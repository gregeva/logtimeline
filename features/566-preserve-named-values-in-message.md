# Feature: Preserve named keys and values that stripping would otherwise remove from the message

## Status

- **Issue:** #566. Sub-issue: #576 (remove the Integration Runtime format's duration read and mask on `N milliseconds`).
- **Phase:** specification, with the architect.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/444-access-log-format-family-and-user-surface.md` § Post-release findings (how the thread segment is derived; the session and user expose transforms); `features/log-format-registry.md` (per-format `message_metrics`: probes and masks); `features/user-defined-metrics.md`.

## Motivating consumer

An analyst who needs messages distinguished by a part of the line that the tool removes while forming the message: one message per thread, per user, per session, or per value of a metric the analyst names, with every other part of the line still stripped as today.

## Requirements (architect's terms)

- **Scope (2026-09-15).** Preservation applies to thread, user, session, and metric values when the metric name is stated. It does not apply to what is truncated or consolidated: those are a far later stage of message processing.
- **Metric values (2026-09-16).** A metric value is masked in the message, `durationMs=123` becoming `durationMs=?`. Naming it (for example `-expose durationMs`) keeps the `123` in place: the replacement becomes conditional. The same holds for `count=` and `bytes=`.
- **Naming (2026-09-16).** The analyst can name either the internal metric name or the key as written in the file. The mask's pattern accepts both spellings of the key, `durationM[sS]`.
- **Loss, not presence** (issue body). The named keys and values are found before anything is stripped; only where they were removed does the value go back in.

## Findings (2026-09-16; release/0.18.2)

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
