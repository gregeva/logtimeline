# Feature: CLI option-parsing and flag-interaction harness (#231)

## Overview

Research/scoping deliverable for #231 (sub-task of #225). Covers four contracts with no automated regression coverage today: value validation (out-of-range, wrong-type, unknown-enum), flag-interaction rules (conflict/precedence/implication), invalid-input handling, and error-message quality. Sibling deliverables `features/225-help-content.md` and `features/225-pattern-files.md` already enumerated the GetOptions surface and filter loading; this picks up from the *resolution and validation* phase inside `adapt_to_command_line_options()`.

Framework dependency: **#226** (`-V` section/category selectivity). The harness itself is unblocked; the highest-value assertion class — a `-V option-resolution` per-flag annotation — needs #226 first.

## § 1. Option-resolution code: structure and citations

`adapt_to_command_line_options()` lives at **`ltl:4080–4418`** (339 lines). Read end-to-end, it executes the following phases in source order:

| Phase | Lines | Concern |
|------:|-------|---------|
| 1 | 4081–4088 | Capture `@ORIGINAL_ARGV`; splice `LTL_CONFIG` env tokens at the front of `@ARGV` via `shellwords`. |
| 2 | 4090 | Legacy alias rewrite: `-?`, `/help`, `/?` → `--help`. |
| 3 | 4092–4168 | `GetOptions(...)` — 75 entries (see `225-help-content.md` § 1); single `or die print_usage(...)` exit. |
| 4 | 4170–4171 | Promote `--start` / `--end` into `%filter_range`. |
| 5 | 4174–4189 | Consolidation (`-g`) value resolution: empty-string default → 85; numeric clamp to 50..99; non-numeric value treated as positional (pushed back to `@ARGV`). |
| 6 | 4192–4216 | Heatmap (`-hm`) value resolution: empty → `duration`; unknown built-in metric routed to UDM-or-filename branch; `time` aliased to `duration`; auto-detect light bg unless overridden. |
| 7 | 4222–4239 | Histogram value validation: four independent clamps (`-hgbpd<1`, `-hgb<0`, `-hgh<3`, `-hgw<20`/`>100`), each emits a `warn` and overrides to a known-good default. |
| 8 | 4248–4265 | Percentile-mode (`-pp` / `-pbpd`) resolution per features/187 § Decision 2 + features/189 § C7. Sets `$percentile_precision_source` for the `=== BIN-COUNTER MODE ===` -V section. |
| 9 | 4267–4275 | Enum validation (hard die): `-du` (`ns\|us\|ms\|s`), `-ru` (`s\|m\|h\|d`). |
| 10 | 4277–4287 | Build compiled filter matchers (`-i/-e/-h` + `-if/-ef/-hf`). |
| 11 | 4289–4300 | Push merged filter regex strings into `@verbose_output`. |
| 12 | 4302–4310 | Short-circuit exits: `-v` → `print_version` + `exit`; `--help` → `print_help` + `exit`. |
| 13 | 4312–4318 | In-process glob; reject non-file entries; die if `@in_files` empty. |
| 14 | 4319–4349 | `-so` value validation: hard die unless in the 23-entry whitelist; map to internal `$sort_key`. |
| 15 | 4351–4392 | UDM parse + heatmap/histogram UDM-metric resolution (hard die on unknown). |
| 16 | 4394 | `$output_timestamp_format` extension for `-s`/`-ms`. |
| 17 | 4395–4415 | Reconstruct positional argument list for CSV header (`$csv_file_args`). |

**Not a uniform validator**: GetOptions is syntactic; phases 5–8 do semantic clamps with `warn`; phases 9, 14, 15 do enum validation with `die`; phase 13 does I/O validation. The closest thing to a central error helper is `print_usage($msg)` (`ltl:1579–1586`), used by five `die` sites (4168, 4269, 4274, 4318, 4319). The two hard-die sites at 4362 and 4381 print raw `Error: ...` strings instead — minor inconsistency.

## § 2. Flag-interaction inventory

Every interaction rule, located in source, with current behavior:

| # | Flags involved | Rule | Behavior | Line |
|---|---|---|---|------|
| 1 | `-pbpd` vs `--percentile-precision` | `-pbpd` wins | Warn-equivalent (annotated in `-V` only) | 4256–4259 |
| 2 | `--percentile-precision` value | Must be 1..9 | Warn + clamp to 5 | 4250–4253 |
| 3 | `-pbpd` value range | Must be 4..616 | Warn + clamp to 53 | 4261–4265 |
| 4 | `--exact-percentiles` | Disables bin-counter consumers | Silent (annotated in `-V`) | 1281–1286, 1322 |
| 5 | `-g` value (`group-similar:s`) | Empty → 85; clamp 50..99; non-numeric → pushed back | Silent clamp + ARGV rewrite | 4174–4189 |
| 6 | `-hm` value (`heatmap:s`) | Empty → `duration`; `time` → `duration`; unknown built-in → UDM-or-filename | Silent default + ARGV rewrite | 4192–4210 |
| 7 | `-hgbpd` | Must be ≥1 | Warn + reset to 8 | 4223–4226 |
| 8 | `-hgb` | Must be ≥0 | Warn + reset to 0 | 4227–4230 |
| 9 | `-hgh` | Must be ≥3 | Warn + clamp to 3 | 4231–4234 |
| 10 | `-hgw` | Must be 20..100 | Warn + reset to 95 | 4235–4238 |
| 11 | `-du` | Must be `ns\|us\|ms\|s` | Hard die via `print_usage` | 4268–4271 |
| 12 | `-ru` | Must be `s\|m\|h\|d` | Hard die via `print_usage` | 4274–4275 |
| 13 | `-so` | Must be one of 23 enum values | Hard die via `print_usage` | 4319 |
| 14 | `-hm <udm>` | UDM name must exist after `parse_udm_configs` | Hard die, custom message | 4354–4363 |
| 15 | `-hg <udm>` | Same as #14 | Hard die, custom message | 4367–4382 |
| 16 | `-s` vs `-ms` | Both set both → `-ms` wins | Silent: elsif at 4484 | 4482–4488 |
| 17 | `-hs` vs `-is` | Compatible (different layers) | Silent | n/a |
| 18 | `--help` | Short-circuit, suppresses all later validation | exit 0 | 4307–4310 |
| 19 | `-v` / `--version` | Short-circuit, suppresses all later validation | exit (status from `exit;`) | 4302–4305 |
| 20 | Unknown built-in metric name to `-hg` | Warn + skip | Warn-and-continue | 4073 |
| 21 | Positional file arg: non-existent path | Glob expands to empty; `@in_files` empties; hard die "unable to open any files" | Hard die | 4313–4318 |
| 22 | Positional file arg: directory | Filtered out by `grep { -f $_ }` at 4316 | Silent skip; if no files remain, dies #21 | 4316 |
| 23 | `LTL_CONFIG` env var | Tokens prepended to `@ARGV` | Silent (echoed only under `-V`) | 4084–4088, 4292–4294 |
| 24 | `-bs` with `-ms` | `bucket_size_seconds = bs/1000`; no minimum | Silent; no clamp (potential bug) | 4485 |
| 25 | `-tw` (hidden) overrides `GetTerminalSize()` | Direct assignment | Silent | 4163 + read in `adapt_to_terminal_settings` |

Notes: row 1's `-V`-only annotation is the **#189 prototype** at `ltl:1278–1327` — the model for this issue's annotation contract. Rows 21–22 share a single diagnostic ("unable to open any files"). `-hm` and `-hg` are *not* mutually exclusive; layout code at `ltl:1332–1337` treats them as additive.

## § 3. Current user-feedback categorization

| Category | Examples (row #s) | Count |
|---|---|---|
| **Hard error + non-zero exit** (`die`) | 2 (GetOptions parse), 11–15, 21 | 7 distinct sites |
| **Warning + override** (`warn` to stderr, run continues) | 2, 3, 7–10, 20 | 7 |
| **Silent override** (no message, behavior changes) | 1, 4, 5, 6, 16, 24, 25 | 7 |
| **Silent ignore** | 17, 22 (when other files supplied), 23 (LTL_CONFIG without `-V`) | 3 |
| **Annotated in `-V` only** | 1, 4 (these overlap "silent" until user runs `-V`) | 2 |

**Exit codes.** All `die` sites in this subroutine exit `255` (Perl's `$! || 255` default). No `exit(1)`/`exit(2)` tiering exists. See § 8.

## § 4. Silent-override gaps

Highest-priority candidates for a `warn` or a `-V option-resolution` annotation:

1. **`-pbpd` overriding `--percentile-precision`** (row 1). Annotated in `=== BIN-COUNTER MODE ===` only — non-`-V` users see nothing. Recommend stderr warn *and* `-V` annotation.
2. **`--exact-percentiles`** (row 4) — documented as deprecated. A deprecation warning on every run is appropriate.
3. **`-g <non-numeric>` pushed back into `@ARGV`** (row 5, `ltl:4181`). `ltl -g logfile` silently sets threshold=85 and feeds `logfile` back as positional. If user meant `-g 90`, no feedback.
4. **`-hm <unknown>` pushed back as filename** (row 6, `ltl:4202`). Same shape.
5. **`-g` clamped to 50..99** (`ltl:4186–4187`). Silent.
6. **`-s` + `-ms` both passed** (row 16). Silent; `-ms` wins.
7. **`-bs` with `-ms` accepting tiny values** (row 24). `-bs 1 -ms` yields a 1ms bucket. Out of scope to fix; harness should pin current behavior.
8. **`LTL_CONFIG` injection** (row 23). Echoed only under `-V`. Recommend `-V option-resolution` row carrying `(env LTL_CONFIG)` annotation; keeps stderr clean by default.

## § 5. Observable surface today

What's testable today:

- **`=== BIN-COUNTER MODE ===`** (`ltl:1278–1327`) — structured `key: value (source)` lines covering `--exact-percentiles`, `-pp`, `-pbpd`. Prototype pattern.
- **`=== Verbose ===`** (`ltl:4291–4299`) — four merged-regex lines (`include`/`exclude`/`highlight`/`threadpool-activity`). Free-form; no per-flag attribution.
- **`=== BENCHMARK DATA ===`** (`ltl:7418–7481`) — TSV `CONFIG\t<key>\t<value>` rows for `terminal_width`, `time_bucket_size`, `bucket_size_seconds`, etc. **No source attribution** — `CONFIG terminal_width 120` doesn't reveal whether it came from `-tw 120` or `GetTerminalSize()`.
- **stderr `warn(...)`** — interleaved with progress noise unless `--disable-progress`. Capturable; format-fragile.
- **`die print_usage($msg)`** — stable two-line `Usage:` prefix + red `Error: $msg` (`ltl:1583`). Regex-matchable.

Everything outside `=== BIN-COUNTER MODE ===` lacks source attribution; this is the gap.

## § 6. Proposed `-V option-resolution` section

### Scope decision

Three options:

- **(a) Full** — every flag's resolved value with source annotation.
- **(b) Selective** — only flags whose resolved value differs from the default, plus override annotations.
- **(c) Anomalies only** — only flags that triggered a conflict/override/clamp during resolution.

**Recommendation: (b) Selective**, with (c) folded in as a guaranteed-emit subset. (a) means ~75 default-noise rows per run; (c) omits load-bearing context (e.g. effective bucket size). (b) bounds the section by what the user changed, includes every override by definition, and degrades to header-only on a defaults-everywhere run.

### Proposed output

For `ltl -V option-resolution -pp 5 -pbpd 100 -bs 60 logfile.log`:

```
=== OPTION RESOLUTION ===
bucket-size: 60 (-bs 60)
percentile-precision: 5 (--percentile-precision 5; overridden)
percentile-buckets-per-decade: 100 (-pbpd 100)
LTL_CONFIG: (empty)
files: 1 matched (logfile.log)
=== END OPTION RESOLUTION ===
```

For `ltl -V option-resolution -pbpd 9999 logfile.log` (clamp case):

```
=== OPTION RESOLUTION ===
percentile-buckets-per-decade: 53 (-pbpd 9999 → clamped to default 53)
files: 1 matched (logfile.log)
=== END OPTION RESOLUTION ===
```

For `ltl -V option-resolution -g logfile.log` (push-back case):

```
=== OPTION RESOLUTION ===
group-similar: 85 (-g without value → default 85)
files: 1 matched (logfile.log)
=== END OPTION RESOLUTION ===
```

Annotation tokens:

- `(<flag> <value>)` — user-supplied.
- `(default)` — would never emit under scope (b); listed for completeness.
- `(<flag> <value>; overridden)` — user-supplied, then beaten by a higher-precedence flag.
- `(<flag> <value> → clamped to default <N>)` — out-of-range, fell back to default.
- `(<flag> <value> → clamped to <bound>)` — out-of-range, fell back to nearest bound.
- `(env LTL_CONFIG)` — sourced from the env-var splice.

### Dependency on #226

The header `=== OPTION RESOLUTION ===` follows the #226 section-naming contract. Until #226 lands selectivity, emit unconditionally under `-V` (same as `=== BIN-COUNTER MODE ===` today). Acceptable interim.

## § 7. Test matrix

Table-driven. `EXIT` = exit code (current behavior). `STDERR_RE` = regex anchoring a match against the diagnostic. `-V ANNO` = expected row in `=== OPTION RESOLUTION ===` (post-implementation; "—" if no row expected).

| # | Input fragment | EXIT | STDERR_RE | -V ANNO |
|--:|---|--:|---|---|
| 1 | `-pbpd 9999 <log>` | 0 | `Invalid -pbpd: 9999` | `percentile-buckets-per-decade: 53 (-pbpd 9999 → clamped to default 53)` |
| 2 | `-pbpd 3 <log>` | 0 | `Invalid -pbpd: 3` | same shape, value 3 |
| 3 | `-pbpd 617 <log>` | 0 | `Invalid -pbpd: 617` | same shape, value 617 |
| 4 | `-pp 0 <log>` | 0 | `Invalid --percentile-precision: 0` | `percentile-precision: 5 (--percentile-precision 0 → clamped to default 5)` |
| 5 | `-pp 10 <log>` | 0 | `Invalid --percentile-precision: 10` | same shape, value 10 |
| 6 | `-pp 5 -pbpd 100 <log>` | 0 | (none today) | `percentile-precision: 5 (--percentile-precision 5; overridden)` + `percentile-buckets-per-decade: 100 (-pbpd 100)` |
| 7 | `-bs abc <log>` | 255 | `^Value "abc" invalid for option bucket-size` (Getopt::Long) | n/a (die before annotation) |
| 8 | `-bs -1 <log>` | 0 | (none today; runs with bs=-1; behavior undefined) | — (pin current behavior; raise separate ticket) |
| 9 | `-so invalidfield <log>` | 255 | `Error: invalid sort type used` | n/a |
| 10 | `-ru x <log>` | 255 | `Invalid rate unit 'x'` | n/a |
| 11 | `-du x <log>` | 255 | `Invalid duration unit 'x'` | n/a |
| 12 | `-hm bogus <log>` (no UDM) | 0 | (none today) | `heatmap: duration (-hm bogus → pushed back as positional)` |
| 13 | `-hm bogus_udm <log> -udm 'real:ms:sum:/x/'` | 255 | `Error: Unknown heatmap metric 'bogus_udm'` | n/a |
| 14 | `-hg bogus <log>` (no UDM) | 0 | `Unknown histogram metric: bogus` | `histogram: (no metrics selected; -hg bogus rejected)` |
| 15 | `-g foo <log>` | 0 | (none today) | `group-similar: 85 (-g foo → non-numeric pushed back; default 85 applied)` |
| 16 | `-g 49 <log>` | 0 | (none today) | `group-similar: 50 (-g 49 → clamped to 50)` |
| 17 | `-g 100 <log>` | 0 | (none today) | `group-similar: 99 (-g 100 → clamped to 99)` |
| 18 | `-hgbpd 0 -hg <log>` | 0 | `Invalid buckets-per-decade value: 0` | `histogram-buckets-per-decade: 8 (-hgbpd 0 → clamped to default 8)` |
| 19 | `-hgh 1 -hg <log>` | 0 | `Histogram height too small: 1` | `histogram-height: 3 (-hgh 1 → clamped to 3)` |
| 20 | `-hgw 19 -hg <log>` | 0 | `Invalid histogram width percent: 19` | `histogram-width: 95 (-hgw 19 → clamped to default 95)` |
| 21 | `--bogus-flag <log>` | 255 | `Unknown option: bogus-flag` | n/a |
| 22 | `-bs <log>` (no value) | 255 | `Option bucket-size requires an argument` | n/a |
| 23 | `<no files>` | 255 | `Error: unable to open any files` | n/a |
| 24 | `nonexistent.log` | 255 | `Error: unable to open any files` | n/a |
| 25 | `/some/directory` | 255 | `Error: unable to open any files` | n/a |
| 26 | `-s -ms <log>` | 0 | (none today) | `time-precision: ms (-ms; -s overridden)` |
| 27 | `LTL_CONFIG="-bs 30" ltl <log>` | 0 | (none today, w/o -V) | `bucket-size: 30 (env LTL_CONFIG)` |
| 28 | `LTL_CONFIG="--bogus" ltl <log>` | 255 | `Unknown option: bogus` | n/a |
| 29 | `-ep <log>` | 0 | (recommend: deprecation warn) | `exact-percentiles: enabled (--exact-percentiles; deprecated)` |
| 30 | `--help` (anywhere) | 0 | empty | n/a (short-circuit before section emission) |

Rows 6, 12, 15–17, 26, 27 are **silent today**. Recommended two-stage rollout: ship the harness pinning current silent behavior as a regression baseline; flip those rows to assert the `-V option-resolution` annotation after #226 + § 6 lands.

## § 8. Exit-code policy

Three options:

- **(a)** Decide here: tiered policy (0 success, 1 user input error, 2 system/I/O error).
- **(b)** Document current ad-hoc behavior (everything = 255 via `die`) as the contract.
- **(c)** File a separate issue; scope #231 to current behavior only.

**Recommendation: (c) — file a separate issue.** Exit-code change is a backward-incompatible CLI contract that affects every shell pipeline using `ltl` in CI; deserves its own issue, release note, and deprecation path. #231's harness should pin current exit codes in column EXIT of § 7 so the future work has a regression baseline. Consistent with #225's deferred-items framing.

## § 9. Backward-compatibility risk

New stderr from § 4 warnings will diff any pipeline capturing `ltl 2>&1`. Mitigations:

- The four high-value warnings (§ 4 rows 1, 5, 16) are gated on specific input shapes — users not passing the combo see no change.
- `-V option-resolution` is gated on `-V`. Zero impact for non-`-V` runs.
- The `--exact-percentiles` deprecation warning would hit every user of that flag — consistent with its documented-deprecated status.
- Roll out in **one release**, called out in release notes. An `LTL_QUIET=1` escape hatch can be deferred unless someone complains.
- Benchmark baselines (`tests/baseline/results/`) capture stderr via `2>&1`; release step 8/9 already re-baselines.

## § 10. ltl code changes required

| # | Item | Effort | Dep |
|---|------|--------|-----|
| 1 | Add `=== OPTION RESOLUTION ===` emitter (new sub `emit_option_resolution_verbose()`) following the `emit_bin_counter_mode_verbose()` template at `ltl:1275`. ~80 LoC. | S | #226 |
| 2 | Track per-flag source string globals (mirrors `$percentile_precision_source` at `ltl:309`) for: `time_bucket_size`, `group_similar_sensitivity`, `heatmap_metric`, `histogram_*` (4 globals), `sort_type`, `print_seconds/print_milliseconds`, `terminal_width`, plus the env-var splice (LTL_CONFIG-sourced flags should carry the `(env LTL_CONFIG)` annotation). ~12 new globals. | M | — |
| 3 | Replace the 7 `warn` calls at 4224, 4228, 4232, 4236, 4251, 4262, 4073 with a single helper `validation_warn($flag, $bad_value, $action)` that emits both stderr and an `@option_resolution_rows` entry. ~30 LoC. | S | — |
| 4 | Add stderr warnings to 4 silent-override sites (§ 4 rows 1, 5, 16, plus a deprecation notice for `-ep` at GetOptions parse time). ~15 LoC. | S | — |
| 5 | Normalize the two `die "Error: ..."` sites at 4362 and 4381 to use `die print_usage("Unknown heatmap metric ...")` for consistent error formatting. ~4 LoC. | XS | — |
| 6 | Exit-code policy normalization | — | **Not in #231**; separate issue per § 8. |

Net code change: **~140 LoC**, all inside `adapt_to_command_line_options()` + one new emitter sub. No data-structure changes outside the GLOBALS section.

## § 11. Harness shape proposal

**Filename**: `tests/validate-cli-options.sh` — bash, table-driven, mirroring `tests/validate-percentile-mode.sh`.

**Fixture**: `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` truncated to 200 lines on first run. (Per MEMORY.md, avoid `localhost_access_log.2025-03-21.txt`.)

**Steps**:

1. Locate `ltl` relative to `$0`; abort if missing/non-executable. Truncate fixture to `tmp/`.
2. Bash array of rows: `id\targs\texpect_exit\tstderr_regex\topt_res_regex` (the four columns of § 7).
3. Per row, run `./ltl --disable-progress -V $args $sample`, capturing stdout/stderr to two temp files.
4. **Assertion A**: exit code matches `expect_exit`.
5. **Assertion B**: `grep -qE "$stderr_regex" stderr.txt` (skip if `-`).
6. **Assertion C** (gated on `OPTION_RESOLUTION_AVAILABLE=1` until § 6 lands): extract `=== OPTION RESOLUTION ===` block; `grep -qE "$opt_res_regex"` (skip if `-`).
7. One-line summary per row; non-zero exit on any failure.

**Why bash**: shape matches `validate-percentile-mode.sh` (table-driven invocations + regex assertions), not `validate-help-content.sh` (source parsing). Each § 7 row maps 1:1 to a harness row — adding a flag interaction adds a row.

## § 12. Open questions

1. **Scope (b) vs (c) for `-V option-resolution`** (§ 6): selective (recommended) or anomalies-only? The default-everywhere run case is the disambiguator — should the section be empty (b) or just the header (c)?
2. **Annotation grammar** (§ 6): is `(<flag> <value> → clamped to default <N>)` the right shape, or should clamps and overrides use distinct verbs (e.g. `; clamped` vs `; overridden`)? The locked #189 pattern uses semicolons exclusively.
3. **Deprecation warning for `--exact-percentiles`** (§ 4 row 4): emit on every run or only under `-V`? Documented-as-deprecated argues for every run; harness-stability argues for `-V`-only.
4. **Backward compatibility** (§ 9): is one-release rollout acceptable, or should the four new warnings be gated behind `LTL_STRICT=1` for one release before becoming unconditional?
5. **Exit-code policy** (§ 8): confirm separate-issue scoping. If anyone objects, the harness has to assert specific tiered codes rather than current `255`-everywhere.
6. **`-bs` with `-ms` and tiny values** (§ 2 row 24): out of scope, but should the harness pin current behavior with `-bs 1 -ms`? Recommend yes — captures any future regression.
7. **`LTL_CONFIG` token attribution** (§ 4 item 8, § 6 example): when an env-supplied flag is overridden by a CLI flag of the same name, should the annotation be `(env LTL_CONFIG; overridden)` or `(env LTL_CONFIG; CLI override)`? Symmetry with the `-pbpd`/`-pp` pattern argues for the first.

## § 13. Effort estimate

**Overall: MEDIUM.**

| Component | Effort |
|-----------|--------|
| ltl code changes (§ 10 items 1–5) | 1 day (gated on #226 for item 1) |
| `tests/validate-cli-options.sh` implementation | 4–6 h |
| CI wiring + first-run debugging | 1 h |
| Backward-compatibility release-notes prose | 30 min |
| **Total** | **1.5–2 days** (after #226) |

The harness alone, pinning current behavior (including silent rows as current-state assertions), is **half a day** with no dependencies. Recommended path: ship the harness now; add the `-V option-resolution` section and flip assertions in a follow-up PR after #226. Preserves small-step iteration.
