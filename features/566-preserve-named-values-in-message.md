# Feature: Preserve named keys and values that stripping would otherwise remove from the message

## Status

- **Issue:** #566. Sub-issue: #576 (remove the Integration Runtime format's duration read and mask on `N milliseconds`).
- **Phase:** specification, with the architect.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/444-access-log-format-family-and-user-surface.md` § Post-release findings (how the thread segment is derived; the session and user expose transforms); `features/log-format-registry.md` (per-format `message_metrics`: probes and masks); `features/user-defined-metrics.md`.

## Motivating consumer

An analyst who needs messages distinguished by a part of the line that the tool removes while forming the message: one message per thread, per user, per session, or per value of a metric the analyst names, with every other part of the line still stripped as today.

## Requirements (architect's terms)

- **Existing fields and structures (2026-09-15).** Among what the tool already extracts, preservation applies to thread, user, session, and metric values when the metric name is stated. It does not apply to what is truncated or consolidated: those are a far later stage of message processing.
- **Metric values (2026-09-16).** A metric value is masked in the message, `durationMs=123` becoming `durationMs=?`. Naming it (for example `-expose durationMs`) keeps the `123` in place: the replacement becomes conditional. The same holds for `count=` and `bytes=`.
- **Naming (2026-09-16).** The analyst can name either the internal metric name or the key as written in the file. The mask's pattern accepts both spellings of the key, `durationM[sS]`.
- **Keys determined from the line itself (2026-09-16).** This is where the power of the enhancement lies. Attributes such as `fileName`, `adId` and `sT` in a Windchill download request's query string are not part of the tool's normal extraction; they are determined from the log line itself. The analyst names a piece of data in the line they want exposed without exposing the entire query string: `--expose fileName` tacks `fileName=<value>` onto the end of the message. The key-value pairs of interest are concatenated onto the message key, separated by a space, without everything else the query string carries.
- **Loss, not presence** (issue body). The named keys and values are found before anything is stripped; only where they were removed does the value go back in.

## Decisions

- **D1 — LOCKED 2026-09-16 (architect) — An exposed key's value is found by the same rule as the counting user-defined metrics' token capture.** `--expose <key>` and `-udm <key>::distinct` read the same value from a line: the key followed by `=` or `:`, the value ending at whitespace, `,`, `;`, `"`, `'`, `]`, `)`, `&` or `?` (`features/user-defined-metrics.md` § Counting Aggregations, row *Default pattern for counting configs*, as revised by § Query-string separators end a counted value), matched against the raw line. One resolution surface: a change to that rule changes both.
- **D2 — LOCKED 2026-09-16 (architect) — Several exposed keys are appended in command-line order.** `--expose fileName --expose adId` appends `fileName=<value> adId=<value>` whatever order the line carries them in, so the same combination of values gives the same message however the producer orders its parameters.

## Findings (2026-09-16; release/0.18.2)

### Where a metric value is masked in the message

| Where | Masks | Formats | Message reads |
|---|---|---|---|
| `format_registry_specs()`, the entry's `message_metrics` `mask` | ` bytes=N`, ` durationMs=N` / ` durationMS=N` | ThingWorx standard | `durationMs=?`, `bytes=?` |
| same key | ` N milliseconds` | Connection Server, Integration Runtime | `? millseconds` (misspelled) |
| `read_and_process_logs()`, count capture (`$message =~ s/ count\s*=\s*\d+/ count=?/g`) | ` count=N` | every format, unless count capture is omitted | `count=?` |

In each case the value is still captured as the metric; only the message text loses it.

### The `N milliseconds` read is split out to #576

The architect's direction (2026-09-16): the Integration Runtime format's read and mask predate user-defined metrics and are unnecessary, since a user-defined metric picks up that single pattern without format-specific logic; they are removed and deprecated under #576, not preserved here. Measured for the filing, `-bs 1440 -n 10 -V`: the Integration Runtime specimen carries no ` N milliseconds` line; a one-day Connection Server log carries 644, all the same WebSocket-authentication timeout notice (`not received within 15000 milliseconds`), read as a 15 s duration and 2.7 hr in total on its message row. The Connection Server entry declares the identical read and mask.
