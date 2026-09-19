# Feature: Discard named keys and values from the message

## Status

- **Issue:** #567. Blocked by #580 (mask UUIDs and IP addresses in the message, keeping their shape). Blocking #581 (deprecate the omit options that `--discard` duplicates) and #582 (name what to expose or discard by a regular expression).
- **Phase:** specification; decisions D1 to D19 locked and acceptance criteria agreed 2026-09-16.
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/566-preserve-named-values-in-message.md` (the sister option `--expose`: D1 the token rule, D3 one option with shorthands, D6 built-in names resolve first, D7 loss not presence); `features/444-access-log-format-family-and-user-surface.md` § Post-release findings (how the thread segment is derived); `features/user-defined-metrics.md` § Counting Aggregations (the token rule); `features/fuzzy-message-consolidation.md` § DD-11: $mask_uuid Processing Order.

## Motivating consumer

An analyst whose messages stay apart because of a part of the line that says nothing about what the message is: a per-request signature and signing time in a download URL, the thread a request ran on, a UUID. Naming that part removes it, and messages differing only in it become one.

## Requirements (architect's terms, 2026-09-16)

- **Purpose.** Remove some string, data, metric or key-value pair from being included in any of the processing and display.
- **Nothing left behind.** The intention is not to indicate that something was there but now is not. The explicit use of the option means something is being removed purposefully.
- **Fields parsed from the line.** What is parsed from a log line is the guide to what can be named. Discarding a parsed field clears its captured value. The fields in scope are session, user, object and thread. Instance and platform are left out (2026-09-16): no surface reads them after capture, so discarding them would change nothing.
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
- **D9 — LOCKED 2026-09-16 (architect), revised the same day — The parsed fields `--discard` accepts are `session`, `user`, `object` and `thread`.** Each clears the captured value (D3, D8). The timestamp, the status or level and the message are not among them. `instance` and `platform` were in scope at first and are left out: the ThingWorx standard format captures both, but nothing after capture reads either, so discarding them would have no observable effect.
- **D10 — LOCKED 2026-09-16 (architect) — A comma-separated list names several parts in one option.** `-d fileName,folderId,sT` is the same as `-d fileName -d folderId -d sT`.
- **D11 — LOCKED 2026-09-16 (architect) — `--expose` accepts the same comma-separated list, delivered in this issue.** `-x fileName,adId` is the same as `-x fileName -x adId`, correcting the finding § `--expose` does not split a comma-separated list.
- **D12 — LOCKED 2026-09-16 (architect) — Nothing of a discarded part survives into any count or capture; filters and highlighting still see the raw line.** Discarding a field or key leaves every count and capture of it empty: the built-in distinct counts (thread-pool activity, the Sessions and Users columns) and a `-udm` metric on the discarded key alike, so the built-in and the user-defined count of the same value never disagree. `-include`, `-exclude` and `-highlight` match the raw line before discard, as selection rather than capture. For a key written in the line no text is removed from the raw line: a `-udm` metric whose key is discarded is switched off when the options are resolved, and the key, value and separator are removed from the message. Counting a value while keeping it from separating messages needs no `--discard`: a counting `-udm` metric already masks its value in the message (`-xqs -udm sign::distinct` writes `sign=?`, measured on two download-request lines).
- **D13 — LOCKED 2026-09-16 (architect) — A name given to both `--expose` and `--discard` is discarded, with a notice.** The value no longer exists when exposed values are appended (D12), so `-x` adds nothing for it; a behavioural notice naming the value prints on every run, `--disable-progress` included, and the run continues.
- **D14 — LOCKED 2026-09-16 (architect) — A built-in name resolves before a key found in the line, as for `--expose` (566 D6); IP addresses are built-in names beside `uuid`.**

  | Name | What `--discard` does |
  |---|---|
  | `thread`, `session`, `user`, `object` | clears the captured value (D9, D12) |
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
- **D19 — LOCKED 2026-09-16 (architect) — A removed UUID or IP address closes the gap it leaves.** Where the same separator (`/` or a space) sits on both sides, the one after it goes with the value; otherwise only the value goes, and brackets around it stay. IP addresses embedded in brackets are planned for: there may be no separator to remove.

  | Message before | After (`-d uuid` or `-d ip`) |
  |---|---|
  | `GET /store/orders/3f9c2a71-8be4-4d0a-9c15-6e2b7d40a8f3/items/summary` | `GET /store/orders/items/summary` |
  | `connection from 10.0.0.1 closed` | `connection from closed` |
  | `ErrorCode(de4882d2-d816-4940-ae83-c2f346e19335), Cause(null)` | `ErrorCode(), Cause(null)` |
  | `client (127.0.0.1) refused` | `client () refused` |
  | `id=3f9c2a71-8be4-4d0a-9c15-6e2b7d40a8f3&x=1` | `id=&x=1` (`-d id` removes the pair instead, D16) |
- **D17 — LOCKED 2026-09-16 (architect) — A UUID or IP address given to both `--mask` and `--discard` is discarded, with a notice.** As D13: the value is removed, a behavioural notice naming it prints on every run, and the run continues. It holds for the deprecated `-uuid` as for `--mask uuid`.
- **D18 — LOCKED 2026-09-16 (architect), revised 2026-09-19 — `-V runtime-config` reports the configuration the user provided.** A new `discard` key lists the resolved names in command-line order, a comma-separated list split and a repeated name kept once at its first position (as 566 D9); `expose` lists only the names still exposed after D13. With `-xqs -x thread -d sign,thread -d duration`: `discard: sign,thread,duration`, `expose: query-string`. The section reports the options the user gave, so a metric named on `--discard` is reported by the `discard` key alone: `omit-durations`, `omit-bytes` and `omit-count` report only when the user gave `-od`, `-ob` or `-oc` (architect, 2026-09-19, correcting the original clause that they report `1` when `--discard` names that metric).

### Performance evidence (architect, 2026-09-16)

`--discard` adds per-line work when it names a key in the line, `uuid` or `ip`. The requirement is a before/after benchmark compared for regression, captured on the base commit before the first line of code and at the completion gate; no prototype.

## Acceptance criteria

Agreed 2026-09-16 (architect). Every run of `ltl` in a harness is shaped to its assertion (`-ni -bs 1440 -oe`, `-o` in a scratch directory where the messages or statistics CSV is read) and checked for ` at <file> line <N>` on stderr. Each assertion is proven to fail against the base build. `tests/validate-message-discard.sh` is new; its fixture `tests/fixtures/message-discard-values.txt` is new and synthetic, ThingWorx standard lines whose messages carry space-separated key-value pairs, UUIDs and IP addresses (`192.0.2.0/24`, `2001:db8::/32`) between spaces, between `/`, and in brackets.

| # | Condition | Observable outcome | Asserted by |
|---|---|---|---|
| 1 | `-xqs -d sign,sT` on download requests whose query string carries `fileName`, `adId`, `sign`, `sT` and `userid` (D1, D2, D10, D16) | No key carries `sign=` or `sT=`; lines differing only in `sign` and `sT` share one message; no key contains `&&`, `?&` or ends in `&` or `?`; the messages CSV is identical to `-xqs -d sign -d sT` | `tests/validate-message-discard.sh`, messages CSV, on `tests/fixtures/message-expose-download-requests.txt` |
| 2 | `-d sign` on each position of D16's table | Each key ends exactly as the table's *After* column | same, on the download fixture staged per case in the harness and on `message-discard-values.txt` |
| 3 | `-xqs -d sign -x fileName` (D6) | Messages CSV identical to `-xqs -d sign` | same, download fixture |
| 4 | `-d thread` with `-tpas` and `-xt` on thread-and-session lines (D8, D9, D12, D13) | No key carries a `[pool]` segment or ` thread=`; `threadpool_population: 0`; one notice on stderr naming `thread` as both exposed and discarded | same, on `tests/fixtures/format-detection/access-thread-session.txt` |
| 5 | `-d session` and `-d user`, each with its `-x` shorthand, on user-and-session lines (D9, D12, D13) | `-V udm-counting` reports `sessions: 0` / `users: 0` in every bucket where the run without `-d` reports more; no ` session=` / ` user=` in any key; the D13 notice for each | same, on `tests/fixtures/format-detection/access-users-sessions.txt` |
| 6 | `-d object` on ThingWorx application log lines (D9) | No key carries an `[object]` segment; keys differing only in the object share one message | same, on `tests/fixtures/format-detection/thingworx-application-log.txt`, staged in the harness so one message carries two objects |
| 7 | `-xqs -d user` on a line carrying user field `alice` and `user=bob` in its query string (D14) | `-V udm-counting` `users: 0`; the key still carries `user=bob` | same, download fixture |
| 8 | `-d duration`, `-d durationMs`, `-d durationMS`; `-d bytes`; `-d count` on ThingWorx standard lines carrying all three metrics (D5, D14) | Messages and statistics CSVs identical to `-od`, `-ob`, `-oc` respectively; the three duration spellings identical to each other | same, on `tests/fixtures/numeric-highlight-boundary.txt` |
| 9 | `-xqs -udm sign::distinct -d sign`; `-udm <name>:… -d <name>` (D12) | The metric produces nothing: no column for it in the statistics CSV, and no `-V udm-counting` line for it | same, download fixture and `tests/fixtures/udm-counting-query-string.txt` |
| 10 | `-d query-string -udm fileName::distinct`; `-xqs -d query-string` (D15, D13) | The first is identical to `-udm fileName::distinct` alone, the metric still counting; the second is identical to the run without `-xqs`, with the D13 notice naming `query-string` | same, download fixture |
| 11 | `-d uuid` and `-d ip` / `-d ipv4` / `-d ipv6` on each case of D19's table and each IP version (D14, D19) | Each key reads exactly as the table's *After* column; `-d ip` removes both versions, `-d ipv4` leaves the IPv6 addresses and `-d ipv6` the IPv4 ones | same, on `message-discard-values.txt` |
| 12 | `--mask uuid -d uuid`, `-uuid -d uuid`, `--mask ip -d ip` (D17) | Identical to `-d uuid` / `-d ip` alone, plus one notice naming the value as both masked and discarded | same |
| 13 | `-include`, `-exclude` and `-highlight` naming the text of a discarded key, `-xqs -d sign` (D12) | The lines selected and highlighted are those the same filters select without `-d sign` | same, download fixture, `-V` classification and occurrence counts |
| 14 | `-x fileName,adId` (D11) | Messages CSV identical to `-x fileName -x adId`; `-V runtime-config` `expose: fileName,adId` | `tests/validate-message-expose.sh`, download fixture |
| 15 | `-xqs -x thread -d sign,thread -d duration`; a repeated name `-d sign -d sign` (D18) | `-V runtime-config` reports `discard: sign,thread,duration` and `expose: query-string`, and no `omit-durations` row, the user not having given `-od`; the repeated name is listed once | `tests/validate-runtime-config.sh` |
| 16 | `--help` (D7) | One `-d, --discard <name>` entry; `docs/usage.md` agrees | `tests/validate-help-content.sh` |
| 17 | No discard option | Output unchanged: the regression goldens, the statistics oracle and every registry self-validation pass without re-blessing | the full harness suite at the completion gate |

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

## Implementation findings (2026-09-19; branch `567-discard-named-values-from-message` off `release/0.18.3`)

Every `ltl` run `--disable-progress -ni -bs 1440 -oe -n 100 -o`, no ` at <file> line <N>` on stderr, captured once to the scratchpad and inspected there.

- **One resolution surface, four registration points.** `resolve_discard_names()` sits beside `resolve_expose_names()` and `resolve_mask_names()` and is called from the same place, after `parse_udm_configs()` and before `build_format_registry()`. An option also needs an entry in `_resolve_short_to_long()`, whose `@specs` list is a hand-maintained mirror of `GetOptions` and builds `%option_provenance`: `-V runtime-config` emits a row only for an option the user supplied, so a `discard` key in `%resolved_values` without that entry would never print.
- **D18's omit-row clause was wrong, and is revised (architect, 2026-09-19).** The clause said `omit-durations`, `omit-bytes` and `omit-count` report `1` when `--discard` names that metric. That cannot hold while `-V runtime-config` reports the configuration the user provided: `-d duration` is reported by the `discard` row, and an omit row for an option the user never gave misrepresents the input. Each option now surfaces itself and only itself, `-od -d duration` printing both rows. The first implementation derived a provenance for the omit row from the variable `--discard` happens to set; that is removed.
- **A cleared field goes to `undef`, not `""`.** Clearing to the empty string left an empty `[]` segment in the message key, because the key branch tests `defined($object)` alone. The per-line reset uses `undef` for a field no format wrote, so that is the value a discard restores, and the key drops the segment entirely (D1). Measured on ThingWorx application-log lines: `-d object` gives `[WARN] [metrics-SystemMetric] AlertProcessingSubsystem: …`, with no bracket pair where the object sat.
- **A discarded field is cleared where nothing has read it yet**, immediately after the control-character normalisation and before the count block, the thread-pool block and the accumulators. One clearing point is what makes the removal reach every surface: `-d thread` on the thread-and-session specimen leaves no `[https-jsse-nio-8443-]` segment *and* renders no thread-pool activity table under `-tpas`; `-d session,user` leaves neither the `sessions` nor the `users` column in the rendered header.
- **A `-udm` metric whose own key is discarded is dropped from `@udm_configs`**, the way a duplicate `-udm` spec is dropped, rather than left to report zero. Setting a flag on the config and leaving it there was not enough: `-V udm-counting` still reported `counting_udms: 1` with the metric's full line. It now reports `counting_udms: none`. A metric counting a key inside a discarded query string keeps counting (`-d query-string -udm fileName::distinct` reports `counting_udms: 1`): it reads the raw line, and D12 switches off only a metric whose own key is named.
- **The `--expose` comma-split defect is fixed and measured.** On the download fixture, `-x fileName,adId` now gives a messages CSV byte-identical to `-x fileName -x adId`; before the change it appended nothing, the whole string being read as one key no line carries.
- **Both separators of the token rule are asserted (architect's question, 2026-09-19).** The rule `-udm`, `-x` and `-d` share accepts `=` or `:` between a key and its value, and the first harness asserted only `=`, leaving the `:` half of the rule unasserted. The fixture gains a line writing the key with a colon and a line writing it both ways, and three assertions: a key written either way is removed, a colon-separated pair takes the separator after it exactly as the equals form does, and a line carrying both spellings loses both occurrences. Measured: `Request done sign:abc status:ok` becomes `Request done status:ok`, `?folderId:1&sign:abc&sT:9` becomes `?folderId:1&sT:9`, and `mixed sign=abc and other sign:def here` becomes `mixed and other here`.
- **Proof the harness asserts.** `tests/validate-message-discard.sh` against the base build (`release/0.18.3:ltl`): 9 passed, 12 failed. The 9 are the guards that prove each fixture carries the case an absence assertion tests, and hold on both builds by design; every assertion of `--discard` behaviour fails without it. Against the new build: 57 passed, 0 failed, and the same counts under `FORCE_COLOR=3`.
- **Two harness defects caught before commit.** An assertion that the `sessions` and `users` columns are gone grepped the whole rendered output, which matched the fixture's own filename `access-users-sessions.txt` in the file list; it now reads the column header row. An assertion on `^users:` matched nothing on either build, so it passed vacuously; it now reads the header row too.

## Completion gate (2026-09-19, this machine, `$version_number` restored to `0.18.3`)

- **Harness suite:** every `tests/validate-*.sh` run once in sequence, each captured to its own file (`CI=1 validate-csv-output.sh`, `CI=1 validate-statistics.sh`, then the rest): 39 of 39 exit 0, every one reporting assertions actually run. `validate-statistics.sh` 22 of 22 scenarios, `validate-regression.sh` 74 assertions, `validate-message-discard.sh` 54, `validate-message-expose.sh` 38, `validate-runtime-config.sh` 51, `validate-help-content.sh` 22. No golden re-blessed.
- **Benchmark** (`single-day-access-log-standard`, this machine, before on the base commit `release/0.18.3` in the main checkout, after on the gate commit in the worktree; 761,698 lines read and included in both, so the comparison is like for like):

  | metric | before | after | change |
  |---|---|---|---|
  | parse/read_files | 8.8 s | 8.7 s | -0.2 % |
  | finalize/calculate_statistics | 101 ms | 97 ms | -4.0 % |
  | total | 8.9 s | 8.8 s | -0.2 % |
  | rss_peak | 101.8 MB | 99.2 MB | -2.6 % |

  No regression: every metric is flat or lower. A run that names nothing pays one scalar test per line for the field clearing and one per retained message for the message removal, which does not rise above the noise floor of a single pair.
