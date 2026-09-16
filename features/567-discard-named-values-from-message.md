# Feature: Discard named keys and values from the message

## Status

- **Issue:** #567. Blocked by #580 (mask UUIDs and IP addresses in the message, keeping their shape). Blocking #581 (deprecate the omit options that `--discard` duplicates).
- **Phase:** specification.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/566-preserve-named-values-in-message.md` (the sister option `--expose`: D1 the token rule, D3 one option with shorthands, D6 built-in names resolve first, D7 loss not presence); `features/444-access-log-format-family-and-user-surface.md` § Post-release findings (how the thread segment is derived); `features/user-defined-metrics.md` § Counting Aggregations (the token rule); `features/fuzzy-message-consolidation.md` § DD-11: $mask_uuid Processing Order.

## Motivating consumer

An analyst whose messages stay apart because of a part of the line that says nothing about what the message is: a per-request signature and signing time in a download URL, the thread a request ran on, a UUID. Naming that part removes it, and messages differing only in it become one.

## Requirements (architect's terms, 2026-09-16)

- **Purpose.** Remove some string, data, metric or key-value pair from being included in any of the processing and display.
- **Nothing left behind.** The intention is not to indicate that something was there but now is not. The explicit use of the option means something is being removed purposefully.
- **Fields parsed from the line.** What is parsed from a log line is the guide to what can be named. Discarding a parsed field (thread, object) clears its captured value.
- **UUID.** `--discard uuid` removes UUIDs. Masking, which leaves the shape of the UUID behind, is a different treatment on a different surface, `--mask uuid` (#580).
- **Keys written in the line.** Found by the same token approach as `-udm` and `-x`: naming the key removes the key, its value and their separator. Regular-expression support for `--expose` and `--discard`, as `-udm` has, would be nice, and is likely a separate enhancement request.
- **Metrics.** The omit options that suppress the metrics (`-od`, `-ob`, `-oc`) are duplicated into `--discard`, a better verb that more broadly covers aspects the omit options cannot. The omit options are to be deprecated later, cleanly, under their own issue (#581).

## Decisions

- **D1 — LOCKED 2026-09-16 (architect) — A discarded part leaves nothing behind.** Neither the key, the value, nor a placeholder remains in the message.
- **D2 — LOCKED 2026-09-16 (architect) — A key written in the line is found by the token rule `-udm` and `-x` use, and goes with its value and separator.** The rule is the one `counting_token_pattern()` builds for the counting user-defined metrics and `--expose` (`features/566-preserve-named-values-in-message.md` D1): one resolution surface for all three.
- **D3 — LOCKED 2026-09-16 (architect) — `thread`, `object` and `uuid` are built-in names.** `thread` and `object` clear the captured value. `uuid` removes UUIDs.
- **D4 — LOCKED 2026-09-16 (architect) — Masking is its own option, and this issue waits on it.** `-m` / `--mask uuid` replaces `-uuid`, whose use then prints an informational notice that it is deprecated in favour of `--mask`; `--mask ip|ipv4|ipv6` masks IP addresses the same way. Filed as #580, which blocks this issue.
- **D5 — LOCKED 2026-09-16 (architect) — `--discard` duplicates the metric omit options.** `--discard duration`, `--discard bytes` and `--discard count` do what `-od`, `-ob` and `-oc` do; the omit options stay for now, and their deprecation is #581.
- **D6 — LOCKED 2026-09-16 (architect) — `-xqs -d sign -d sT -x fileName` exposes the query string without `sign` and `sT`.** `-x fileName` adds nothing, because the exposed query string already carries `fileName` (566 D7); `-d sign` and `-d sT` remove those two key-value pairs.
- **D7 — LOCKED 2026-09-16 (architect) — One option names anything to discard.** `-d <name>` / `--discard <name>`, with one help entry. Neither spelling collides with an existing option.

## Findings (2026-09-16; release/0.18.2 at a2873b2)

### Where each nameable part reaches the message today (code audit)

| Name | Captured by | Reaches the message as | Other surfaces reading it |
|---|---|---|---|
| `thread` | the format spec's `field_map` (`thread`, 8 formats) | `[pool]` in the message key: the thread with a trailing `-<digits>` removed (the thread-pool block in `read_and_process_logs()`, `$threadname = defined $threadpool ? $threadpool : $thread`), cut to 20 characters at key construction | the thread-pool accumulators (`%log_threadpools`, `-tpas`, `-tpa`); `-x thread` |
| `object` | `field_map` (`object`, 6 formats); the `hoist_cpp_object` transform | `[object]` in the message key, its last 25 characters | consolidation grouping metadata (`$truncated_object`) |
| `uuid` | not captured | in the message text; `-uuid` replaces it with `########-####-####-####-############` just before the exposed values are appended | consolidation's UUID-normalised similarity scoring |
| `duration`, `bytes` | `field_map`, and the ThingWorx `message_metrics` probes, which also mask ` durationMs=N` / ` bytes=N` to `?` | as the mask only | every metric column, statistics, heatmap, histogram; suppressed today by `-od` / `-ob` |
| `count` | the count capture in `read_and_process_logs()` (` count=N`) | as ` count=?` | count columns and statistics; suppressed today by `-oc` |
| a key written in the line | not captured | in the message text, when the format keeps that part of the line (a query string only with `-xqs`) | `-udm <key>::<counting function>`, `-x <key>` |

- *After #566, session, user and the query string no longer enter the message unless exposed.* `-xs` and `-xu` append `session=` and `user=` only when given, and the `strip_query_string` transform removes the query string unless `-xqs` is given. Nothing of theirs reaches a message that `-x` did not put there.
- *A `-` thread already reaches no message.* #565 shipped in this release: the thread-pool block sets no pool name for a bare `-`.
