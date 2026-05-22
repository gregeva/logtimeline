# Feature Requirements: Format-Detection Regression Harness (#228)

## Status

- **Type:** Research deliverable (no implementation)
- **Umbrella issue:** #225 (high-priority test-harness coverage gaps)
- **Sub-task:** #228 (regression-testing log-format auto-detection)
- **Hard dependency:** #226 (`-V` selectivity / per-section emission)
- **Adjacent context:** `features/duration-unit-autodetection.md`, `features/log-format-registry.md` (#17, #23)

## Background / Why This Matters

ltl's parsing loop is a chained `if/elsif` regex cascade in `read_and_process_logs()` (`ltl:4564-4774`). The first pattern that matches wins, sets an implicit format identifier (`$match_type` 1-13), and routes downstream extraction. No format ID is ever written to output. The implicit knowledge "match_type 3 is a Tomcat access log with `%D`" is invisible to any test that does not eyeball the rendered graph.

The risk this harness addresses: **a `%D` field is microseconds in Apache HTTP Server 2.x but milliseconds in Tomcat 9.** A 1000× off-by-unit error sails past percentile assertions because every percentile scales the same way — P50 still equals P50, just at the wrong absolute magnitude. Without a unit-level assertion, the regression is undetectable.

## 1. Enumerated Built-in Formats

Source: `ltl:4623-4774`. There are **13 numbered match types**, plus the CSV path that re-uses `match_type=13`. Each is identified by which regex matches first.

| match_type | Canonical name (code comment) | Detection regex anchor (ltl line) | Fields extracted | Duration unit | Source of unit knowledge |
|---:|---|---|---|---|---|
| 1 | ThingWorx Standard Log Format | `^YYYY-MM-DD HH:MM:SS.sss±0000 [L: …] [O: …] [I: …] [U: …] [S: …] [P: …] [T: …] …` (4623) | timestamp, level, object, instance, user, session, platform, thread, message; opt. `bytes=`, `durationMS=` (4628-4629) | **ms** (pattern hint: `durationM[sS]=`) | implicit — embedded in ms-only regex |
| 2 | ThingWorx Remote Access Client (RAC) | `^[?YYYY-MM-DDTHH:MM:SS.sss…] [L:?TRACE…]` (4660) | timestamp, level | n/a (no duration captured) | n/a |
| 3 | Tomcat access log w/ `%D` + opt. `%I`, `%S` | `^(.+? ){3}[ts] "REQ" STATUS BYTES DURATION THREAD? SESSION?$` (4681) | timestamp, request, status, bytes, **duration**, thread, session | **ms (assumed)** | none — value passed through raw |
| 4 | Tomcat / Nginx Common Access (no duration) | `^(.+? ){3}[ts] "REQ" STATUS BYTES$` (4695) | timestamp, request, status, bytes | n/a | n/a |
| 5 | ThingWorx Connection Server JSON | `^{"@timestamp":"…","…","level":"…"` (4710) | timestamp, level | n/a | n/a |
| 6 | Java 11 GC log (info-level pause) | `^[?ts]…[info][gc] GC(n) descr (from)->(to)(size) Nms` (4718) | timestamp, message, heap from/to/size, **duration** | **ms** (literal `ms` in regex) | explicit (regex literal) |
| 7 | ThingWorx Analytics V2 (adaptor/sync/async) | `^LEVEL [ts] …` (4727) | level, timestamp, message | n/a | n/a |
| 8 | ThingWorx Analytics worker | `^ts [thread] LEVEL …` (4737) | timestamp, thread, level, message | n/a | n/a |
| 9 | JBoss / Jersey access log | `^… "REQ" STATUS BYTES "REFERER" "AGENT" DURATION$` (4745) | timestamp, request, status, bytes, **duration** | **ms (assumed)** | none |
| 10 | ThingWorx Connection Server standard | `^ts [thread] LEVEL OBJECT - msg` + ` N milliseconds` (4643, 4648) | timestamp, thread, level, object, message, opt. **duration** | **ms** (literal ` milliseconds`) | explicit |
| 11 | ThingWorx Edge C SDK | `^LEVEL ts message` (4757) | level, timestamp, object (`*.cpp:NN`), message | n/a | n/a |
| 12 | Apache Tomcat / CodeBeamer `[%Dms] [%Ts]` | `^… [%Dms] [%Ts]` (4666) | timestamp, request, status, bytes, **duration**(`[Nms]`) | **ms** | explicit (literal `ms`) |
| 13 | CSV (lazy two-line validation) | `detect_and_parse_csv_header()` invoked after two failed log-pattern matches (4776-4821) | timestamp col + UDM columns + opt. message cols; epoch detected at 4606 / 4797 | depends on `-du` and per-UDM unit declaration | user (`-du`) or per-UDM config |

**Implicit "is access log" flag** (`$is_access_log`) is set by types 3, 4, 9, 12 unconditionally; by 1/10 only when a duration or bytes field actually parsed; by 6 always; by 13 always. It drives whether latency stats are computed. It is *not* a format ID.

**Generic Java/Logback fallback** at `ltl:4655` re-uses `$match_type=1` for any line matching `^YYYY-MM-DD HH:MM:SS.sss+ZZZZ [L: LEVEL]` that did not match the full ThingWorx pattern. This collapses two distinct formats under one match_type.

## 2. Duration-Unit Detection Deep-Dive

There is **no value-range autodetection**. `features/duration-unit-autodetection.md` (architect review 2025-01-25) deferred it pending the format-registry refactor (#23). Today, unit knowledge comes from four sources:

1. **Format-embedded literals.** Types 6, 10, 12 include the unit token (`milliseconds`, `ms`, `s`) in the regex itself.
2. **Format-assumed default = ms.** Types 3, 9 capture a bare trailing integer and assume milliseconds. Apache HTTP Server 2.x with `%D` (microseconds) is silently misclassified — 1000× error.
3. **Manual user override.** `-du ns|us|ms|s` (declared `ltl:1692`, parsed `ltl:4103/4128/4268-4270`, applied `ltl:4896-4898` via `convert_duration_to_ms()` at `ltl:2280-2290`). **Global only** — applied to every file in the run.
4. **CSV epoch timestamps.** `ltl:4904-4908` divides the epoch column by `-du` factor, treating `-du` as the unit of the timestamp itself.

The per-file index row carries `ts_precision` (`ltl:4541, 4968`) — that's **timestamp precision**, not duration unit. Detected by whether the timestamp string contained fractional seconds.

`docs/test-logs.md` line 37 claims "ltl auto-detects the unit based on value ranges." **Incorrect** — fix as part of #228 prep.

## 3. Observable Surface Today

| Surface | Format ID emitted? | Duration unit emitted? |
|---|---|---|
| `-V` (existing sections: `=== Verbose ===`, `=== INDEX READ-BACK ===`, `=== BIN-COUNTER MODE ===`, `=== Consolidation Summary ===`) | no | no |
| `=== BENCHMARK DATA ===` block (`ltl:7418-7481`) | no | no |
| Bar graph header / scale | no | latency unit shown only as `format_time()` output magnitude (`ltl:3987-3988`: `us`/`ms`/`s`) — derived from value, not detection |
| CSV (`-o`) column headers | no | no |
| stderr | progress line shows filename only (`ltl:4595`) | no |
| Index file `ltl-index.csv` | no | no (carries `ts_precision`, not duration unit) |
| Internal `$match_type` | per-line only, never printed | n/a |

**The harness cannot assert format detection today.** Only second-order signals (latency-column presence, value magnitude) are inferable — neither catches the ms-vs-µs trap.

## 4. Proposed `-V format-detection` Section

Modeled on `=== INDEX READ-BACK ===` (`ltl:1211-1268`): one section, per-file blocks, deterministic ordering, machine-parseable.

```
=== FORMAT DETECTION ===
duration_unit_source: user      # user|default (no autodetect today)
duration_unit_override: us      # value of -du, or "-" if unset
files: 2
file: logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log
  format: tomcat_access_with_duration
  match_type: 3
  is_access_log: yes
  ts_precision: s
  duration_unit_assumed: ms     # the format's built-in assumption
  duration_unit_applied: us     # after -du / -udm overrides
  duration_field: trailing_integer
  matched_lines: 9214
  unmatched_lines: 0
  first_match_line: 1
file: logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log
  format: thingworx_standard
  match_type: 1
  is_access_log: yes
  ts_precision: ms
  duration_unit_assumed: ms
  duration_unit_applied: us     # -du is global, even if format embeds ms
  duration_field: durationMS=
  matched_lines: 281044
  unmatched_lines: 132
  first_match_line: 1
=== END FORMAT DETECTION ===
```

Field locking (per `features/187-histogram-bin-counter-percentiles.md` §Decision 8): section name, field names, `format` enum values, `duration_unit_*` enum values are **contract-stable**; numeric values evolve freely. The `format` slug is the new public ID — today's `$match_type` 1-13 maps 1:1 to stable slugs via one central table. The harness asserts against slugs, not match_type numbers.

## 5. Test-Fixture Mapping

| format slug | match_type | Representative fixture (under `logs/`) | Notes |
|---|---:|---|---|
| `thingworx_standard` | 1 | `ThingworxLogs/ApplicationLog.2025-05-05.0.log` | no duration |
| `thingworx_standard_with_metrics` | 1 (with `durationMS=`) | `ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log` | duration, bytes, count |
| `thingworx_generic_logback` | 1 (fallback) | none confirmed; `ApplicationLog-improperlyRead.log` may overlap | **GAP — needs deliberate fixture** |
| `thingworx_rac_client` | 2 | none in `logs/` | **GAP** |
| `tomcat_access_with_duration` | 3 | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (Tomcat 9, ms) | primary ms baseline |
| `tomcat_access_common` | 4 | none confirmed pure (most files have duration) | **GAP — needs trimmed sample** |
| `connection_server_json` | 5 | none in `logs/` | **GAP** |
| `java_gc_log` | 6 | none in `logs/` | **GAP** |
| `tw_analytics_v2` | 7 | none in `logs/` | **GAP** |
| `tw_analytics_worker` | 8 | none in `logs/` | **GAP** |
| `jboss_access` | 9 | none in `logs/` | **GAP** |
| `connection_server_standard` | 10 | none in `logs/` | **GAP** |
| `tw_edge_c_sdk` | 11 | `UDM/rea-assets-5402_…trace_logs.log` (referenced in test-logs.md §UDM) | confirm format match |
| `tomcat_codebeamer` | 12 | `Codebeamber/codebeamer_access_log.2025-10-29.txt` | explicit `[Nms]` |
| `csv` | 13 | `UDM/connection-server-custom-metrics.csv`, `UDM/results_data_idonly-timestampMs.csv` | epoch-ms and human-ts variants |
| `apache_httpd_microseconds` | 3 (today) | `AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | **Misclassified — same regex as Tomcat 9. Run with `-du us` today.** |

**Gap count: 7 of 14 slugs have no fixture.** Fixture authoring is the heaviest single piece of #228.

Per repo memory: do **not** use `localhost_access_log.2025-03-21.txt` (corrupt lines).

## 6. Assertion Shape

Driven from a TSV (`tests/format-detection/scenarios.tsv`) — `file, expected_format, expected_unit_applied, expected_match_count_min, notes`. Test runner invokes `ltl -V --disable-progress <file>`, parses the `=== FORMAT DETECTION ===` block, asserts equality.

```
assert_format Tomcat9-ms              \
    logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt \
    --expect-format tomcat_access_with_duration --expect-unit ms

assert_format ApacheHTTP2-us          \
    logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log \
    -du us \
    --expect-format tomcat_access_with_duration --expect-unit us

assert_format CodeBeamer              \
    logs/Codebeamber/codebeamer_access_log.2025-10-29.txt \
    --expect-format tomcat_codebeamer --expect-unit ms

assert_format ThingWorxScriptLog      \
    logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log \
    --expect-format thingworx_standard_with_metrics --expect-unit ms

assert_format CSV-epoch-ms            \
    logs/UDM/results_data_idonly-timestampMs.csv \
    -du ms \
    --expect-format csv --expect-unit ms
```

## 7. Format-Misdetection Canaries

Negative-case fixtures that prove detection actually discriminates. Each is a hand-crafted ~50-line synthetic file under `tests/format-detection/canaries/`.

| Canary | Construction | Expected outcome | Failure mode caught |
|---|---|---|---|
| `tomcat_with_microsecond_durations.log` | Tomcat 9 shape, trailing integers 100k-1M | `tomcat_access_with_duration`, unit ms (today). With `-du us`, P50 in ms-band; without, inflated 1000× | Future autodetect silently flipping unit |
| `apache_with_millisecond_durations.log` | Same regex, values 1-2000 | `tomcat_access_with_duration`; no warning today | Future autodetect false-positive on legit ms Tomcat |
| `thingworx_no_metrics.log` | ThingWorx without `durationMS=`/`bytes=` | `thingworx_standard`, `is_access_log: no` | Accidental access-log promotion |
| `codebeamer_brackets_only_ms.log` | `[Nms]` present, `[Ts]` absent | Falls through to `tomcat_access_with_duration` | match_type 12 regex drift |
| `csv_lookalike_log.log` | Comma-separated fields, line 2 also matches a log pattern | Detects as log format, not csv | Lazy-CSV regression (#107) |
| `json_no_timestamp.log` | `{"level":"INFO",…}` no `@timestamp` | Unmatched | match_type 5 over-eager match |
| `gc_log_no_unit_token.log` | GC line, bare numeric pause, no `ms` literal | Unmatched | Regex literal drift |

## 8. Risk of Detection-Refactor Constraint

The `=== BIN-COUNTER MODE ===` precedent shows that locking a `-V` section into the test suite creates a stability contract. For format-detection the trade-off is sharper because #23 will fully rewrite the detection path.

**Recommended contract scope:**

- **Locked:** section name, field names, `format:` slug values for existing formats, `duration_unit_*` enum (`ns|us|ms|s|-`), `duration_unit_source` enum.
- **Free to evolve:** numeric counts, the heuristic that arrives at the slug, order in which patterns are tried, any new slugs added.
- **Migration guarantee:** when #23 lands, every existing fixture must resolve to the **same slug** as before. Implementation under the slug may change completely.

Narrower than the bin-counter contract — format detection only guarantees "this file → this slug → this unit answer." Heuristic internals are deliberately excluded.

## 9. ltl Code Changes Required

| Change | Effort | Notes |
|---|---|---|
| Add `=== FORMAT DETECTION ===` emitter (depends on #226) | medium | New `emit_format_detection_verbose()` modeled on `emit_index_readback_verbose()`. Per-file counters `%format_detection{$file}` accumulated in `read_and_process_logs()`. |
| Define `%match_type_to_slug` table | low | One hash near `## GLOBALS ##`. Names must survive the #23 registry rewrite — they become the registry's primary keys. |
| Track per-file format resolution | low | On first `$is_line_match`, record `match_type`/`first_match_line`. Per-file `matched_lines`/`unmatched_lines` counters in existing loop. |
| Distinguish ThingWorx-standard vs generic-logback under match_type 1 | low | Add a sub-flag at `ltl:4655`. Without it the slug is ambiguous. |
| Fix `docs/test-logs.md` line 37 autodetect claim | trivial | Docs only. |
| Optional `--explain-detection` human-readable trace | medium | Likely overkill; skip in v1. |

Total: **medium**. Risky part is slug names surviving the #23 rewrite.

## 10. Harness Shape

Directory: `tests/format-detection/`.

```
tests/format-detection/
├── scenarios.tsv              # file, args, expected_format, expected_unit, min_matches
├── canaries/                  # synthetic negative-case fixtures
│   ├── tomcat_with_microsecond_durations.log
│   ├── thingworx_no_metrics.log
│   └── ...
├── run.sh                     # iterates scenarios.tsv
└── golden/                    # captured -V FORMAT DETECTION blocks per scenario
```

Numbered steps for `run.sh`:

1. Read `scenarios.tsv`; for each row, invoke `./ltl -V --disable-progress <args> <file>` and extract the `=== FORMAT DETECTION ===` block.
2. Parse `format:`, `duration_unit_applied:`, `matched_lines:` per file block.
3. Assert against TSV expectations; record pass/fail.
4. On fail, diff captured block against `golden/<scenario>.txt`.
5. Exit non-zero on any failure; emit TSV summary for CI.

Mirrors `tests/validate-regression.sh` shape so one CI job can run both.

## 11. Open Questions

1. **Slug naming.** Directive-shaped (`tomcat_access_combined_with_d`), server+version (`tomcat9_access_d_ms`), or semantic (`access_log_with_trailing_duration`)? Choice affects #23 registry YAML organization.
2. **Per-file `-du`.** Today `-du` is global. A run mixing Apache (µs) and Tomcat 9 (ms) is unsolvable. Gate scenarios to one-file-per-run, or motivate a `-du <file>=us` syntax via #228?
3. **Multi-file aggregation.** When two files have different formats, which "wins" for places that don't disambiguate per-file (latency-column header, CSV output)?
4. **Generic-logback overlap.** match_type 1 covers both full ThingWorx and bare-prefix Logback. Split into two slugs, or keep as one bucket with a sub-field?
5. **Apache HTTP Server misclassification.** It matches type 3 today. The harness will codify the misclassification. When the registry splits it, do we file a separate issue and update the harness in lockstep, or block the split on harness coverage?

## 12. Effort Estimate

| Piece | Effort |
|---|---|
| `-V` section emitter + slug table | low-medium (~1-2 days) |
| Fixture authoring (7 missing formats + 7 canaries) | **medium-high (~3-5 days)** |
| `scenarios.tsv` + `run.sh` | low (~0.5 day) |
| Golden-file capture + review | low (~0.5 day) |
| Documentation sweep | low |
| **Overall** | **Medium** (~1 sprint) |

**Critical path: missing fixtures.** Detection assertions are only as good as fixture coverage. Without closing the 7 gaps in §5, the harness asserts only the already-working formats.

## Related

- **Blocks #228** (this harness)
- **Depends on #226** (`-V` selectivity — without it, the new section bloats every run)
- **Coordinates with #23** (format registry rewrite — slug names become registry keys)
- **Coordinates with #17** (duration-unit autodetection — when it ships, `duration_unit_source` enum gains `auto`)
- **References:** `ltl:4564-4774` (match cascade), `ltl:2280-2290` (unit conversion), `ltl:4896-4908` (override application), `features/duration-unit-autodetection.md`, `features/log-format-registry.md`, `docs/test-logs.md`
