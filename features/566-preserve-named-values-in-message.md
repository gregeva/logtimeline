# Feature: Preserve named keys and values that stripping would otherwise remove from the message

## Status

- **Issue:** #566. Sub-issue: #576 (remove the duration read and mask on `N milliseconds` from the Integration Runtime and Connection Server formats), delivered into this branch by PR #577.
- **Phase:** implementation complete; acceptance criteria agreed 2026-09-16, completion gate passed on the same day.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/444-access-log-format-family-and-user-surface.md` § Post-release findings (how the thread segment is derived; the session and user expose transforms); `features/log-format-registry.md` (per-format `message_metrics`: probes and masks); `features/user-defined-metrics.md`.

## Motivating consumer

An analyst who needs messages distinguished by a part of the line that the tool removes while forming the message: one message per thread, per user, per session, or per value of a metric the analyst names, with every other part of the line still stripped as today.

## Requirements (architect's terms)

- **Existing fields and structures (2026-09-15).** Among what the tool already extracts, preservation applies to thread, user, session, and metric values when the metric name is stated. It does not apply to what is truncated or consolidated: those are a far later stage of message processing.
- **Metric values (2026-09-16).** A metric value is masked in the message, `durationMs=123` becoming `durationMs=?`. Naming it (for example `-expose durationMs`) keeps the `123` in place: the replacement becomes conditional. The same holds for `count=` and `bytes=`.
- **Naming (2026-09-16).** The analyst can name either the internal metric name or the key as written in the file. The mask's pattern accepts both spellings of the key, `durationM[sS]`.
- **Keys determined from the line itself (2026-09-16).** This is where the power of the enhancement lies. Attributes such as `fileName`, `adId` and `sT` in a Windchill download request's query string are not part of the tool's normal extraction; they are determined from the log line itself. The analyst names a piece of data in the line they want exposed without exposing the entire query string: `--expose fileName` tacks `fileName=<value>` onto the end of the message. The key-value pairs of interest are concatenated onto the message key, separated by a space, without everything else the query string carries.
- **Help and usage (2026-09-16).** There is a lot of overlapping syntax here. The existing options are kept; the help does not over-advertise every option, as it would be too long. The help is intuitive and coherent. `-xt`, `-xs`, `-xu` and `-xqs` are aliases, not new options needing a help entry of their own: they are covered in the one help entry for `-x`, referenced there in shorthand.
- **Loss, not presence** (issue body). The named keys and values are found before anything is stripped; only where they were removed does the value go back in.

## Decisions

- **D1 — LOCKED 2026-09-16 (architect) — An exposed key's value is found by the same rule as the counting user-defined metrics' token capture.** `--expose <key>` and `-udm <key>::distinct` read the same value from a line: the key followed by `=` or `:`, the value ending at whitespace, `,`, `;`, `"`, `'`, `]`, `)`, `&` or `?` (`features/user-defined-metrics.md` § Counting Aggregations, row *Default pattern for counting configs*, as revised by § Query-string separators end a counted value), matched against the raw line. One resolution surface: a change to that rule changes both.
- **D2 — LOCKED 2026-09-16 (architect) — Several exposed keys are appended in command-line order.** `--expose fileName --expose adId` appends `fileName=<value> adId=<value>` whatever order the line carries them in, so the same combination of values gives the same message however the producer orders its parameters.
- **D3 — LOCKED 2026-09-16 (architect) — One option names anything to expose; the existing options are its aliases, and the thread gains one.** `-x <name>` / `--expose <name>` (`-x thread`, `-x fileName`); `-xt` / `--expose-thread` is an alias for `-x thread`, and `-xs` (session), `-xu` (user) and `-xqs` (query string) are kept as aliases in the same way. One help entry, for `-x`, covers them all and references the aliases in shorthand. Neither `-x` nor `--expose` collides with an existing option (the parser runs without abbreviation).
- **D4 — LOCKED 2026-09-16 (architect) — An exposed thread is appended to the end of the message as a key-value pair.** `-x thread` / `-xt` adds the thread as a key-value pair at the end of the message, as for keys determined from the line, so the full, unique thread name is visible rather than the segment cut to 20 characters.
- **D5 — LOCKED 2026-09-16 (architect) — An exposed session and user are appended the same way.** `-x session` / `-xs` and `-x user` / `-xu` add `session=<value>` and `user=<value>` at the end of the message, in place of the bracketed value they place at the front of the message today, so every exposed value reads the same way: legible, and machine readable.
- **D6 — LOCKED 2026-09-16 (architect) — A built-in name resolves before a key found in the line; the query string is named `query-string`.** `thread`, `session`, `user`, `query-string`, the metric names and their keys as written (`duration`, `durationMs`, `durationMS`, `bytes`, `count`) and any `-udm` metric name name the value the tool already extracts; any other name is a key found in the line by the D1 rule. `-x user` on a line carrying both a user field and `user=bob` in its query string exposes the user field. `-xqs` is the alias of `-x query-string`.
- **D7 — LOCKED 2026-09-16 (architect) — A key found in the line is appended only when the formed message no longer yields its value.** After the message is formed, the D1 rule is applied to it: if it yields the same value as on the raw line, the key survived and nothing is added; otherwise ` key=<value>` is appended, in command-line order (D2). A line that carries no value for the key gets nothing. `-xqs -x fileName` gives the same message as `-xqs` alone. A named metric (`durationMs`, `bytes`, `count`, a `-udm` metric) keeps its number in place instead of `?`, and is not appended.
- **D8 — LOCKED 2026-09-16 (architect) — The message key's length limit is unchanged.** Exposing a value does not change where the key is cut: the terminal width in the rendered output, 350 characters with `-o` or `-g`. The limit already adapts to the terminal width; an appended value beyond it is not kept in the key.
- **D9 — LOCKED 2026-09-16 (architect) — A name given more than once is exposed once, at its first position.** `-x fileName -xqs -x fileName` resolves to `fileName,query-string`; the value appears once in the message.

### Prototype trigger waived (architect, 2026-09-16)

The new per-line cost trigger (`prototype/README.md`) is waived. The cost arises only when `-x` names a key found in the line; measured by proxy (§ Premises measured on the base build) at +26% on one key over the Windchill download-request log. The only performance evidence required is the completion gate's before/after benchmark, with any anomaly investigated.

## Acceptance criteria

Draft for agreement. Every run of `ltl` in a harness is shaped to its assertion (`-ni -bs 1440 -oe`, `-o` in a scratch directory where the messages CSV is read) and checked for ` at <file> line <N>` on stderr. Each assertion is proven to fail against the base build.

| # | Condition | Observable outcome | Asserted by |
|---|---|---|---|
| 1 | `-x fileName` on access-log download requests whose query string carries `fileName`, `adId` and a per-request `sign` (D7) | Each key ends ` fileName=<value>`; one message per distinct `fileName`; no other query-string parameter is in the key; a line without `fileName` gets the key it has without `-x` | `tests/validate-message-expose.sh`, messages CSV, on a committed download-request fixture |
| 2 | `-xqs -x fileName` on the same lines (D7: loss, not presence) | Messages CSV identical to `-xqs` alone | same |
| 3 | `-x fileName -x adId`, the two parameters in either order on the line (D2) | Keys end ` fileName=<f> adId=<a>`; lines differing only in parameter order share one message; `-x adId -x fileName` ends ` adId=<a> fileName=<f>` | same |
| 4 | `-x <key>` and `-udm <key>::distinct` for each counted key of the query-string fixture the counting metrics are pinned on (D1) | The values appended by `-x` are exactly the distinct values `-V udm-counting` reports; both are produced by the one sub that builds the counting token pattern, called from `parse_udm_configs()` and from the expose resolution | same, on `tests/fixtures/udm-counting-query-string.txt` |
| 5 | `-x user` on a line carrying user field `alice` and `user=bob` in its query string (D6) | Key ends ` user=alice` | same, download-request fixture |
| 6 | `-xt` and `-x thread` on the thread-and-session fixture (D4) | Identical messages CSV; each key ends ` thread=<full thread name>`, one message per distinct thread; the bracketed thread segment is as without `-x`; a `-` thread gets no `thread=`; `null` gives ` thread=null` | same, on `tests/fixtures/format-detection/access-thread-session.txt` staged with `-` threads |
| 7 | `-xs` ≡ `-x session`, `-xu` ≡ `-x user` (D5, D6) | Keys end ` session=<value>` / ` user=<value>` with no bracketed value at the front of the message; a `-` or empty value adds nothing; `-x session -x user` appends in that order | `tests/validate-message-expose.sh`; `tests/validate-udm-counting.sh` `scenario_users_column` changes to read `user=` |
| 8 | `-x durationMs`, `-x durationMS`, `-x duration`; `-x bytes`; `-x count`; `-x <name>` of a `-udm` metric, on ThingWorx standard lines carrying all three (requirements; D6, D7) | The named number stays in place (`durationMS=123`), the other masks still read `?`; the three duration spellings give identical CSVs; the metric values captured are unchanged (STATS CSV identical to the run without `-x`) | `tests/validate-message-expose.sh`, on `tests/fixtures/numeric-highlight-boundary.txt` |
| 9 | `-x query-string` ≡ `-xqs` (D6) | Identical messages CSV | same |
| 10 | Any `-x` combination above | Success/failure classification counts identical to the run without `-x` | same, `-V` classification counts |
| 11 | No expose option | Output unchanged: the regression goldens, the statistics oracle and every registry self-validation pass without re-blessing | the full harness suite at the completion gate |
| 12 | `-xqs -x fileName -xu` (D2, D3) | `-V runtime-config` reports `expose` with the resolved names in command-line order, `query-string,fileName,user`; the existing three `expose-*` keys still report their state | `tests/validate-runtime-config.sh` |
| 13 | `--help` (D3) | One `-x, --expose <name>` entry that names `-xt`, `-xs`, `-xu` and `-xqs`; no separate rows for them; `docs/usage.md` agrees | `tests/validate-help-content.sh` |

## Completion gate (2026-09-16, this machine, `$version_number` restored to `0.18.2`)

- *Full harness suite.* Every `tests/validate-*.sh` exits 0, `CI=1 validate-csv-output.sh` then `CI=1 validate-statistics.sh` first; 37 harnesses, each captured once. `tests/validate-message-expose.sh` asserts 36 times over ten scenarios.
- *Assertions proven to bite.* Six mutations of a copy of the tool, each caught by the assertions naming the behaviour it broke: no survival check, appends in reverse order, the thread pool name in place of the thread, a masked metric that was named, a prepended user, and the count mask left in force.
- *No expose option is no change.* The messages and statistics CSVs of the base build and the changed build are identical on four fixtures covering access logs with thread and session fields, ThingWorx standard lines carrying all three metrics, and the query-string counting fixture.
- *Real data.* On the Windchill Apache access log with signed download URLs, `-du us -x fileName` writes 22,431 rows carrying a `fileName` value, 22,431 distinct, matching the distinct count measured on the base build; the download requests, four keys before, are one key per file.
- *Before/after benchmark*, `single-day-access-log-standard` and `multi-day-custom-logs-standard`, same machine and session: total time 27.5 s to 26.0 s (−5.6%; access log −7.4%, custom logs −4.6%), peak memory 275.0 MB to 275.4 MB (+0.2%), lines read and included identical. The largest single memory move is +304 KB on the access log (+0.3%), inside the noise the 5% rule allows.

## Findings (2026-09-16; release/0.18.2)

### Premises measured on the base build (`0.18.2-566`), 2026-09-16

Every run `-ni --disable-progress` with bare `-V`, no ` at <file> line <N>` on stderr in any run.

- *Download requests: the appended key survives the key's length limit at CSV width, not at the default terminal width.* The Windchill Apache access log with signed download URLs (`-du us -bs 1440 -o`): 74,305 download-request lines form 4 distinct keys today, because the URL path is a fixed template that never carries the file name; each line carries a 14-character `fileName` value, 22,431 distinct. Keys today are 110 to 121 characters; with ` fileName=<value>` appended, 134 to 145. The key is cut at the terminal width (`max_log_message_length`, 120 by default; 160, 200 and 250 at those `--terminal-width` settings) or at 350 with `-o` or `-g`: at 120 every one of the 74,305 lines loses the appended value, at 160 and above none does.
- *The counting-metric token rule reads the expected values.* `-udm fileName::distinct` on the same log reports 22,431 distinct from 74,305 occurrences.
- *One per-line key match costs about a quarter of the run on this log.* `-du us -bs 1440 -n 10`, three runs each, `TIMING total`: without the metric median 1.165 s (1.151 to 1.170), with `-udm fileName::distinct` 1.473 s (1.469 to 1.479), +0.308 s (+26%), peak memory about +3.2 MB. A proxy for the cost of `-x fileName`, which performs the same match.
- *Threads.* The Tomcat access log carrying thread and session fields (517,684 lines, `-xqs -bs 1440 -o`): 183 distinct full thread names in one pool, no `-` threads; 46,421 distinct messages today, reproduced exactly by an independent count over status, the thread's first 20 characters and the message. With the full thread distinguishing messages, 104,070 distinct messages (2.24 times).

### Where a metric value is masked in the message

| Where | Masks | Formats | Message reads |
|---|---|---|---|
| `format_registry_specs()`, the entry's `message_metrics` `mask` | ` bytes=N`, ` durationMs=N` / ` durationMS=N` | ThingWorx standard | `durationMs=?`, `bytes=?` |
| same key | ` N milliseconds` | Connection Server, Integration Runtime | `? millseconds` (misspelled) |
| `read_and_process_logs()`, count capture (`$message =~ s/ count\s*=\s*\d+/ count=?/g`) | ` count=N` | every format, unless count capture is omitted | `count=?` |

In each case the value is still captured as the metric; only the message text loses it.

### The `N milliseconds` read is split out to #576

The architect's direction (2026-09-16): the Integration Runtime format's read and mask predate user-defined metrics and are unnecessary, since a user-defined metric picks up that single pattern without format-specific logic; they are removed and deprecated under #576, not preserved here. Measured for the filing, `-bs 1440 -n 10 -V`: the Integration Runtime specimen carries no ` N milliseconds` line; a one-day Connection Server log carries 644, all the same WebSocket-authentication timeout notice (`not received within 15000 milliseconds`), read as a 15 s duration and 2.7 hr in total on its message row. The Connection Server entry declares the identical read and mask; the architect extended #576 to remove both (2026-09-16).

### #576: remove the `N milliseconds` duration read and mask from the Integration Runtime and Connection Server formats

**Requirement (#576 "Done when").** Neither format reads a duration from, or masks a number in, ` N milliseconds` in the message; an analyst who wants that value gets it with a user-defined metric.

**Surfaces.** The `message_metrics` blocks of the `mt10` (`connection_server_standard`) and `mt10ir` (`integration_runtime_standard`) entries in `format_registry_specs()`, compiled by `compile_format_scan_sub()` into the probe, the mask and the per-line `$metrics_observed = 1`; each entry's `samples`/`expect` records (load-time self-validation); `-V format-detection` `metrics_observed` per file; the release notes.

**Acceptance criteria.**

| # | Condition | Observable outcome | Asserted by |
|---|---|---|---|
| 1 | A line of either format carrying `… completed processing in 152 milliseconds` | The extraction record keeps `152 milliseconds` in the message (no `? millseconds`), `duration` is undefined and `metrics_observed` is 0 | Each entry's `samples`/`expect` records, checked by the registry self-validation on every run: the Connection Server record is changed to this expectation and the Integration Runtime entry gains such a sample. Proven to fail against the base build |
| 2 | A file of such lines bound to either member | `-V format-detection` reports `metrics_observed: no` and the same selected member as before (`mt10ir` for day-first dates with a day > 12, `mt10` otherwise) | `tests/validate-format-detection.sh`, a scenario per member on committed synthetic fixtures staged with no name evidence. Proven to fail against the base build (`metrics_observed: yes`) |
| 3 | Lines without ` N milliseconds` | Extraction unchanged | The unchanged first `expect` record of each entry; on the corpus Integration Runtime specimen (no such line) the `-V` output and render are identical before and after, timings excepted |
| 4 | The Connection Server and Integration Runtime corpus files | Selection unchanged (`selected`, `candidates`, `confidence` identical before and after); on the Connection Server log the only change is the removed read: the timeout notice rows keep `15000 milliseconds` and carry no duration | Existing variant-selection scenarios in `tests/validate-format-detection.sh`, plus a before/after `-V` and render comparison on both corpus files, recorded below |
| 5 | The replacement `-udm "elapsed:ms::/ (\d+) milliseconds/"` on the same lines | Same values on the same lines as the removed read | Base build, both reads in one run at a one-second bucket (one line per bucket): per-bucket `duration` equals the metric's sum, min and max, recorded below; `tests/validate-udm-specs.sh` pins the metric's run-wide production on both fixtures |
| 6 | Every run above | No ` at <file> line <N>` on stderr | The runtime-warning check in each harness |

**Findings.**

- *The replacement reproduces the removed read (criterion 5).* Base build (`0.18.2-566`), synthetic 8-line files of each shape (5 lines carrying ` N milliseconds`, values 152, 48, 3017, 152 and 7 or 15000), `-s -bs 1s -o -udm "elapsed:ms::/ (\d+) milliseconds/"`: in the STATS CSV every one of the 5 buckets holding a value has `duration` = `elapsed_ms_sum`, `duration_min` = `elapsed_ms_min`, `duration_max` = `elapsed_ms_max`, 0 differences, for both the Integration Runtime and the Connection Server file. The metric name `elapsed` does not collide with the built-in `duration`.
- *Criterion 1 holds, and fails against the read.* With both `message_metrics` blocks removed, each entry's self-validation passes with the `152 milliseconds` record expecting the number kept, `duration` undefined and `metrics_observed` 0. Restoring either block in a copy of the changed tool stops the run at load with exit 25: `extraction parity failure for entry 'mt10ir' sample 3 field 'message': got '… completed processing in ? millseconds', expected '… completed processing in 152 milliseconds'` (and the same for `mt10` sample 2).
- *Criterion 2 holds, and fails against the base build.* The new format-detection scenario passes on the changed tool (`mt10ir` and `mt10` each selected by evidence at confidence 1.00, 8 of 8 lines matched, `metrics_observed: no`); the same harness on the base build fails exactly its two `metrics_observed: no` assertions (the base reports `yes`). The replacement pin in `tests/validate-udm-specs.sh` fails when one fixture value is changed (3017 to 3018).
- *Criteria 3 and 4, corpus files, bare `-V`, `-bs 1440 -n 10`, base against changed build.* The Integration Runtime specimen: output identical apart from the version banner and the run's own time and memory. The one-day Connection Server log: `selected: mt10`, `candidates: mt10=5.75,mt10ir=0.00`, `confidence: 1.00` identical; what changes is only what follows from reading no duration: `metrics_observed: yes` becomes `no`, the timeline loses its duration and latency columns, the duration statistics stores report no population (bucket store 4 to 0), the histogram-bin-counter blocks report `feature_not_active` in place of `user_opt_out`, and the 644-occurrence timeout notice row loses its 15 s duration statistics and 2.7 hr total. On the synthetic Connection Server file the MESSAGES CSV carries `… was not received within 15000 milliseconds; closing connection` and `… completed processing in 152 milliseconds`. No regression golden reads a Connection Server or Integration Runtime file.
