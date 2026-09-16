# Feature: Discard named keys and values from the message

## Status

- **Issue:** #567. Blocked by #580 (mask UUIDs and IP addresses in the message, keeping their shape). Blocking #581 (deprecate the omit options that `--discard` duplicates) and #582 (name what to expose or discard by a regular expression).
- **Phase:** specification.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/566-preserve-named-values-in-message.md` (the sister option `--expose`: D1 the token rule, D3 one option with shorthands, D6 built-in names resolve first, D7 loss not presence); `features/444-access-log-format-family-and-user-surface.md` § Post-release findings (how the thread segment is derived); `features/user-defined-metrics.md` § Counting Aggregations (the token rule); `features/fuzzy-message-consolidation.md` § DD-11: $mask_uuid Processing Order.

## Motivating consumer

An analyst whose messages stay apart because of a part of the line that says nothing about what the message is: a per-request signature and signing time in a download URL, the thread a request ran on, a UUID. Naming that part removes it, and messages differing only in it become one.

## Requirements (architect's terms, 2026-09-16)

- **Purpose.** Remove some string, data, metric or key-value pair from being included in any of the processing and display.
- **Nothing left behind.** The intention is not to indicate that something was there but now is not. The explicit use of the option means something is being removed purposefully.
- **Fields parsed from the line.** What is parsed from a log line is the guide to what can be named. Discarding a parsed field clears its captured value. The fields in scope are session, user, instance, platform, object and thread.
- **UUID and IP address.** `--discard uuid` removes UUIDs; `--discard ip`, `ipv4` and `ipv6` remove IP addresses, the same names `--mask` takes. Masking, which leaves the shape of the UUID behind, is a different treatment on a different surface, `--mask uuid` (#580).
- **Keys written in the line.** Found by the same token approach as `-udm` and `-x`: naming the key removes the key, its value and their separator. Regular-expression support for `--expose` and `--discard`, as `-udm` has, is a separate enhancement (#582).
- **Several names in one option (2026-09-16, surfaced trying `--expose`).** `-d fileName,folderId,sT` operates on the three keys; repeating the option, `-d fileName -d folderId -d sT`, also works.
- **`--expose` takes the same list (2026-09-16).** `-x` is fixed to handle a comma-separated list as part of the `--discard` work.
- **Metrics.** The omit options that suppress the metrics (`-od`, `-ob`, `-oc`) are duplicated into `--discard`, a better verb that more broadly covers aspects the omit options cannot. The omit options are to be deprecated later, cleanly, under their own issue (#581). Only data-side omit options are duplicated: `-osum` (`--omit-summary`) hides a rendered section and is not part of `--discard`; nor are `-oe`, `-or`, `-ov` and `-os`.

## Decisions

- **D1 — LOCKED 2026-09-16 (architect) — A discarded part leaves nothing behind.** Neither the key, the value, nor a placeholder remains in the message.
- **D2 — LOCKED 2026-09-16 (architect) — A key written in the line is found by the token rule `-udm` and `-x` use, and goes with its value and separator.** The rule is the one `counting_token_pattern()` builds for the counting user-defined metrics and `--expose` (`features/566-preserve-named-values-in-message.md` D1): one resolution surface for all three.
- **D3 — LOCKED 2026-09-16 (architect) — `thread`, `object` and `uuid` are built-in names.** `thread` and `object` clear the captured value. `uuid` removes UUIDs.
- **D4 — LOCKED 2026-09-16 (architect) — Masking is its own option, and this issue waits on it.** `-m` / `--mask uuid` replaces `-uuid`, whose use then prints an informational notice that it is deprecated in favour of `--mask`; `--mask ip|ipv4|ipv6` masks IP addresses the same way. Filed as #580, which blocks this issue.
- **D5 — LOCKED 2026-09-16 (architect) — `--discard` duplicates the metric omit options.** `--discard duration`, `--discard bytes` and `--discard count` do what `-od`, `-ob` and `-oc` do; the omit options stay for now, and their deprecation is #581.
- **D6 — LOCKED 2026-09-16 (architect) — `-xqs -d sign -d sT -x fileName` exposes the query string without `sign` and `sT`.** `-x fileName` adds nothing, because the exposed query string already carries `fileName` (566 D7); `-d sign` and `-d sT` remove those two key-value pairs.
- **D7 — LOCKED 2026-09-16 (architect) — One option names anything to discard.** `-d <name>` / `--discard <name>`, with one help entry. Neither spelling collides with an existing option.
- **D8 — LOCKED 2026-09-16 (architect) — A discarded value is gone from the whole run, as if it had never been on the line.** Discard is never partial: every surface that reads the value sees nothing. `--discard thread` leaves no `[pool]` segment in the message, and the thread-pool activity surfaces (`-tpas`, `-tpa`) and `-x thread` get no thread; the same holds for every name `--discard` accepts.
- **D9 — LOCKED 2026-09-16 (architect) — The parsed fields `--discard` accepts are `session`, `user`, `instance`, `platform`, `object` and `thread`.** Each clears the captured value (D3, D8). The timestamp, the status or level and the message are not among them.
- **D10 — LOCKED 2026-09-16 (architect) — A comma-separated list names several parts in one option.** `-d fileName,folderId,sT` is the same as `-d fileName -d folderId -d sT`.
- **D11 — LOCKED 2026-09-16 (architect) — `--expose` accepts the same comma-separated list, delivered in this issue.** `-x fileName,adId` is the same as `-x fileName -x adId`, correcting the finding § `--expose` does not split a comma-separated list.
- **D12 — LOCKED 2026-09-16 (architect) — Nothing of a discarded part survives into any count or capture; filters and highlighting still see the raw line.** Discarding a field or key leaves every count and capture of it empty: the built-in distinct counts (thread-pool activity, the Sessions and Users columns) and a `-udm` metric on the discarded key alike, so the built-in and the user-defined count of the same value never disagree. `-include`, `-exclude` and `-highlight` match the raw line before discard, as selection rather than capture. For a key written in the line no text is removed from the raw line: a `-udm` metric whose key is discarded is switched off when the options are resolved, and the key, value and separator are removed from the message. Counting a value while keeping it from separating messages needs no `--discard`: a counting `-udm` metric already masks its value in the message (`-xqs -udm sign::distinct` writes `sign=?`, measured on two download-request lines).
- **D13 — LOCKED 2026-09-16 (architect) — A name given to both `--expose` and `--discard` is discarded, with a notice.** The value no longer exists when exposed values are appended (D12), so `-x` adds nothing for it; a behavioural notice naming the value prints on every run, `--disable-progress` included, and the run continues.
- **D14 — LOCKED 2026-09-16 (architect) — A built-in name resolves before a key found in the line, as for `--expose` (566 D6); IP addresses are built-in names beside `uuid`.**

  | Name | What `--discard` does |
  |---|---|
  | `thread`, `session`, `user`, `instance`, `platform`, `object` | clears the captured value (D9, D12) |
  | `uuid`; `ip`, `ipv4`, `ipv6` (`ip` either version) | removes UUIDs, or IP addresses, from the message; the patterns are the ones `--mask` defines (#580), one resolution surface for both options |
  | `duration`, `durationMs`, `durationMS` | what `-od` does (D5); the three spellings are one name |
  | `bytes`, `count` | what `-ob` and `-oc` do (D5) |
  | the name of a `-udm` metric | switches that metric off (D12) |
  | any other name | a key found in the line: switches off a `-udm` metric counting that key (D12), and is removed from the message with its value and separator (D1, D2) |

  `-d user` on a line carrying a user field and `user=bob` in its query string discards the user field and leaves `user=bob`.
- **D15 — LOCKED 2026-09-16 (architect) — `query-string` is a built-in `--discard` name, so `-x` and `-d` accept the same names.** It removes the query string from the message: alone it changes nothing, since the query string is removed unless exposed; with `-xqs` the query string is discarded and the D13 notice prints. A `-udm` metric counting a key inside the query string reads the raw line and keeps counting (D12 switches off only a metric whose own key is discarded).
- **D16 — LOCKED 2026-09-16 (architect) — A discarded key-value pair takes the separator that follows it, or, at the end, the one before it; every occurrence goes.** The separator is `&`, `?` or a space. With `-d sign`:

  | Message before | After |
  |---|---|
  | `…regen?folderId=1&sign=abc&sT=9` | `…regen?folderId=1&sT=9` |
  | `…regen?sign=abc&sT=9` | `…regen?sT=9` |
  | `…regen?folderId=1&sign=abc` | `…regen?folderId=1` |
  | `…regen?sign=abc` | `…regen` |
  | `Request done sign=abc status=ok` | `Request done status=ok` |
  | `Request done sign=abc` | `Request done` |

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

### `--expose` does not split a comma-separated list (0.18.2-567, 2026-09-16)

`-x fileName,adId` on two Windchill download-request lines (`-ni -du us -bs 1440 -oe -o -V runtime-config`): exit 0, no notice, no ` at <file> line <N>` on stderr; `-V runtime-config` reports `expose: fileName,adId`, the same line two separate names would give; the messages CSV holds one message ending `….regen` with nothing appended, because the whole string `fileName,adId` is read as one key that no line carries (`resolve_expose_names()` trims each name and does not split it).
