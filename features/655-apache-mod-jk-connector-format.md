# #655 — Read Apache mod_jk connector logs

Issue #655 (Read Apache mod_jk connector logs). Owning records for the surface:
`features/log-format-registry.md` (system of record for formats),
`features/453-success-failure-classification-event-ledger.md` (classification and
the event-ledger property), `features/476-per-format-log-level-declarations.md`
(level declarations), `features/444-access-log-format-family-and-user-surface.md`
(what a family is). Target: the 0.18.6 patch release, forward-ported to
release/0.19.0 afterwards.

The logs this specification was measured on are a temporary set in the local
corpus, provided for this work and removed once it ships. They are not listed in
`docs/test-logs.md` and no harness names them. Harness coverage rests on committed
scrubbed fixtures; the real files served the measurements below and serve the
rendered check at implementation, whose figures are recorded here without paths.

## What this is for

An analyst reading a web tier's access log beside the Tomcat connector log of the
same server. The access log says a request ended 413 or 503; the connector log says
why: the request could not be marshalled into an AJP packet, or every Tomcat worker
was down. The output is the ordinary multi-file run: one timeline whose legend
numbers each file's format, the connector's ERROR lines bucketed beside the access
log's 4xx and 5xx lines, and a messages table naming each connector failure once
with its count. From it the analyst decides which access-log failures the connector
explains, and when.

## Requirement

From the issue, in its terms: LogTimeLine reads Apache mod_jk connector logs,
which today are entirely unmatched, because the connector's errors correlate one for
one with access-log statuses and explain them.

## Findings

Measured on release/0.18.6 (`c56ae7b`), on 28 connector logs (3,781 lines) from
three deployments of a PLM application behind Apache HTTP Server and the mod_jk
connector, two servers each, one file per day, beside their access logs (common
format plus a microsecond duration, stamp `+0000`).

### F1 — one line shape across every connector file

A read-only pass parsed every line with one expression: 3,781 of 3,781, no blank,
continuation or CRLF lines, monotonic order, each weekday agreeing with its date.

| Part | Observed | Lines |
|---|---|---|
| Stamp | `[Www Mmm dd HH:MM:SS.mmm yyyy]`, millisecond fraction, no zone | 3,781 |
| Day | two digits (only days 19 to 31 occur; the space-padded single-digit form is not observable) | 3,781 |
| Request-id bracket | `[NO-ID]`; no `-`, no real id, no line without the bracket | 3,781 |
| Process and thread | `[pid:tid]`, decimal; 24 distinct process ids, 813 distinct thread ids | 3,781 |
| Level | `[error]`, lower case; no other word | 3,781 |
| Location | `function::source (line): ` | 3,781 |
| Worker prefix | `(tomcatN) ` at the head of the message, per-worker functions only | 1,230 |
| No worker prefix | the load balancer's own lines | 2,551 |

Location forms and the length of `function::source`: `service::jk_lb_worker.c` (23,
2,551 lines), `ajp_marshal_into_msgb::jk_ajp_common.c` (38, 1,055),
`ajp_service::jk_ajp_common.c` (28, 78), `ajp_send_request::jk_ajp_common.c` (33,
62), `ajp_get_reply::jk_ajp_common.c` (30, 35). The same message is written from
different source lines in different deployments (17 distinct function, source and
line combinations), so more than one connector build is present; every one writes
the millisecond stamp.

Message families (numbers as N):

| Function | Message | Lines | For the request |
|---|---|---|---|
| `service` (balancer) | `All tomcat instances failed, no more workers left` | 2,547 | answered 503 |
| `service` (balancer) | `unrecoverable error 502, request failed. Tomcat failed in the middle of request, we can't recover to another instance.` | 4 | answered 502 |
| `ajp_marshal_into_msgb` | `(tomcatN) failed appending the …`: query string of length N (649), remote port N (116), activation state (92), local address (86), route (38), remote user (23), header name or value (47), message end (3), secret (1) | 1,055 | answered 413 |
| `ajp_send_request` | `(tomcatN) connecting to backend failed. Tomcat is probably not started or is listening on the wrong port (errno=N)` | 62 | one worker refused |
| `ajp_service` | `(tomcatN) connecting to tomcat failed (rc=N, errors=N, client_errors=N).` (74), `(tomcatN) sending request to tomcat failed (unrecoverable),  (attempt=N)` (4) | 78 | per-worker attempt |
| `ajp_get_reply` | `(tomcatN) Tomcat is down or refused connection. No response has been sent to the client (yet)` (31), `… network problems. Part of the response has already been sent to the client` (4) | 35 | per-worker attempt |

Variable numbers make 411 distinct message texts. Scrubbed lines of the two shapes:

```
[Tue Aug 25 14:19:57.981 2026] [NO-ID] [1111:2222] [error] ajp_marshal_into_msgb::jk_ajp_common.c (621): (tomcat1) failed appending the remote port 41754
[Fri Aug 21 11:51:02.114 2026] [NO-ID] [1111:2222] [error] service::jk_lb_worker.c (1687): All tomcat instances failed, no more workers left
```

### F2 — the motivating use holds on real data

Each connector line was matched to the access log of the same server and day,
consuming each access line once.

**413, one connector line per response, at the same second.** Deployment A, both
servers, every day held:

| Server | Days | Marshalling errors | Access 413 lines | Same second | Within one second |
|---|---|---|---|---|---|
| first | 10 | 555 | 555 | 553 | 555 |
| second | 11 | 500 | 500 | 499 | 500 |

The connector writes no zone, the access log writes `+0000`, and the seconds agree.
`ltl` converts no zone on any format (the `tz` key of the time contract is declared
but never read), so a connector log and its own server's access log line up
whatever the zone.

**503, one balancer line per response, within two seconds.** The access log stamps
a request at arrival; the connector writes when the last worker fails:

| Deployment, server, day | Balancer lines | Access 503 lines | Same second | Within 1 s | Within 2 s |
|---|---|---|---|---|---|
| A, first, day 1 | 39 | 39 | 32 | 37 | 38 |
| A, second, day 1 | 56 | 52 | 45 | 51 | 52 |
| B, second, day 2 | 2,352 | 2,352 | 2,285 | 2,344 | 2,344 |
| B, second, day 3 | 59 | 59 | 55 | 59 | 59 |

Per-worker lines are not one per request: a request failing over both workers
writes two lines per worker and one balancer line (88 connector lines for 39 failed
requests in one restart window). A worker error is not always a failed request:
eight per-worker lines on one day accompany no 503; seven are failovers the
balancer recovered. The four 502 lines match their access lines only by completion
time (arrival plus a duration of 1.6 to 3.6 s).

**What one timeline shows**, the counts each bucket must carry once the entry
exists: deployment A, first server, the 413 day, hourly: connector ERROR 1, 8, 14,
20, 25, 14, 8, 4, 2, 6 in the hours 11 and 14 to 22, equal to the hour's 413s (the
rendered 4xx is larger: 51 at 14:00, carrying other 4xx statuses). Deployment B,
second server, the 503 burst, one-minute: balancer lines 90, 2,258, 4 at 11:50 to
11:52 against 503s 97, 2,255, 0, then 21,237 500s at 11:54 to 11:56 with no
connector line, the backend's own answers.

### F3 — what the shipped tool does today

Captured with bare `-V`: one 102-line connector file gives `lines_unmatched: 102`,
`sample_formats: -` and `Read 102 lines, however no lines matched any of the
patterns within the timeframe.` All 28 files in one run: 3,781 read, 3,781
unmatched, every one of the 19 scanned entries at 0 in `match_counts:`, so nothing
shadows a new pattern. Beside its access log (`-du us -bs 60`) the access log binds
`access_common_duration` with 0 unmatched lines, the connector file shows
`format: -` with the file-pane bracket `[-]`, and the legend is
`1=access_common_duration` alone.

### F4 — the two-format run, previewed

The connector lines of the 413 day were transcribed, in the scratchpad only, into a
diagnostics shape the shipped tool reads and run beside the real access log. The
legend numbers both formats and the hourly rows carry `ERROR: N` beside `4xx: N`.
The success and failure percentage columns, on by default for the access log alone,
are not shown: they are on by default only when every bound file is an event ledger
declaring both outcomes (`classification_columns_visible()`, D15 of the
percentage-columns record), and the run prints the note naming the format without
a success rule. With `-scl` the failure count holds both the 413 and its connector
line: 70 at 14:00 for 62 failed requests, and `errRate` 1.2 per minute against 1.0
for the access log alone. This is the behaviour of any diagnostics format read
beside an access log.

### F5 — what the registry needs (code audit)

- **Time layout.** `compile_format_time_parser()` and the inline parse in
  `format_entry_block_src()` know `apache_clf` (`dd/Mon/yyyy:HH:MM:SS`) and the
  `iso_*` layouts (fixed `substr` offsets). Neither reads `Www Mmm dd HH:MM:SS yyyy`.
- **Fraction.** `frac => 'fixed3'` truncates the stamp at offset 19
  (`substr($timestamp_str, 19) = ''`), which here would cut the year off;
  `frac => 'generic'` (`s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/`) strips 1 to 6 digits
  correctly.
- **Date cache.** `%timestamp_date_cache` is shared by every layout, keyed
  `yyyy-MM-dd` (ISO) and `dd/Mon/yyyy` (CLF); a new layout's key must collide with
  neither form.
- **Probes.** `format_probe_layout()` returns undef for a non-ISO layout, so the
  date probes do not apply, as for the access family.
- **Level case.** The category gate in `read_and_process_logs()` is
  `exists $log_level_set{$category_bucket}`, exact and case-sensitive: a captured
  `error` is counted under `unregistered_levels` and dropped. `emerg` has no
  same-spelled member (`EMERGENCY` exists). The default failure rule
  `^(?:ERROR|FATAL|CRITICAL)$` does not name `EMERGENCY`. The precedent for mapping
  a producer's own tokens is the `wgm_msgtype` transform over `%wgm_msgtype_names`
  (Workgroup Manager letters to names), which leaves an unmapped token for the gate
  to report.
- **Thread-pool fold.** `( $threadpool ) = $thread =~ /(.*)-\d+$/` does not fold
  `pid:tid`. Measured: 411 distinct message keys from function and message, 1,512
  with the thread id, 1,642 with `pid:tid`; the 2,547 identical balancer lines split
  across 430 keys; `-tpas` would list 813 thread handles as pools.
- **Object truncation.** The message key keeps the object's last 25 characters
  (`substr($object, length($object) - 25)`): four of the five `function::source`
  forms lose the head of the function; the function names alone (7 to 21
  characters) survive whole.
- **Classification.** An absent `classification` inherits the default (failure
  only); D24 gate 7 of the registry record requires a level named in a literal
  criterion to be in the vocabulary; `ERROR` and `EMERGENCY` both are.
- **User surfaces.** `print_help_formats()` lists a non-family entry under Other
  formats; `-lf <name>` seats any scanned entry (`apply_format_pin()`); the
  file-pane legend numbers each bound format. None needs code for a new entry.
- **Counts that move.** `-V format-registry` `entries`, `scanned_entries`,
  `scan_slots`, `static_order` and `-V format-detection / scan` `entries`, asserted
  by `tests/validate-format-registry.sh` (inventory) and
  `tests/validate-format-detection.sh` (scan-telemetry). #656 (read unified GC logs
  written without the level-and-tags decoration) adds entries on the same release;
  whichever lands second re-bases these counts.

### F6 — what the connector's source can write that the held files do not

From the connector's logging code (`jk_util.c` `set_time_str()`, `jk_logger.h`, the
request-id change of release 1.2.48):

| Axis | Held files | Also possible |
|---|---|---|
| Stamp fraction | milliseconds | none (`JkLogStampFormat` without a fraction, or no `gettimeofday`), microseconds (`%q`), any custom strftime layout |
| Day | two digits | space-padded single digit (`%d` is zero-padded in the default layout; custom layouts may differ) |
| Request-id bracket | always, `[NO-ID]` | absent before release 1.2.48; `-` with no log context; a real id from mod_unique_id |
| Level | `error` | `trace`, `debug`, `info`, `warn`, `emerg` |
| Request-level lines | none | written under `JkRequestLogFormat`, a different shape |

### Citation corrections

- The issue's sample line pairs source line 637 with `failed appending the
  activation state ACT`; in the held logs line 637 writes `failed appending the
  local address …` and the activation-state message comes from line 657.
- "Matches the 503s of the restart windows" holds for the balancer line alone;
  the per-worker lines around it are several per failed request (F2).
- Confirmed as cited: the 102-line file, and 555 and 500 marshalling errors on
  the two servers.

## Standing decisions that govern the surface

- D5 of the access-family record: a family is the shapes of one root format,
  sharing status-family classification and the duration note. The connector is
  not a member; a shared timeline needs no family (F4).
- D7 of the classification record: a diagnostics log inherits failure on its
  error levels with no success rule.
- D24 gates of the registry record: every entry's samples must match, extract and
  classify as declared at every start.
- D47 of the registry record: a variant group fills one scan slot and exists for
  shapes nothing on the line distinguishes.

## Locked decisions (architect, 2026-10-03)

### D1 — one entry per line shape the connector's source can emit

The connector format is a set of registry entries, one per line shape the
connector's logging code can write (F6), each named so the name says how its
shape differs from the others. They are built toward what the code emits and
tested against the held files where a shape exists in them; shapes no held file
shows are proven by their self-validation samples, written from the source and
marked synthetic in the fixture manifest. Base name `apache_mod_jk` for the shape
the held files write (millisecond stamp with the request-id bracket); the other
names carry a suffix naming the difference, settled when the shapes are
enumerated at implementation.

### D2 — all six level words are mapped

`trace`, `debug`, `info`, `warn`, `error`, `emerg` map to `TRACE`, `DEBUG`, `INFO`,
`WARN`, `ERROR`, `EMERGENCY`, all in the static vocabulary. An unmapped word stays
as written and is reported by the unregistered-level path, not lost.

### D3 — a connector error is a failure

Failure when the category matches `^(?:ERROR|EMERGENCY)$`, no success rule, not an
event ledger (the connector writes a line for what fails, not for every request).
In a run beside an access log each failed request is counted once as 4xx or 5xx
and once as ERROR (F4), as any diagnostics format beside an access log already is.

### D4 — fields

The object is the function name alone. The message is the text after `): `, with
the `(tomcatN)` worker prefix kept, since it tells backends apart; numbers are not
masked by the entry. The weekday, request-id bracket, `pid:tid`, source file and
line number are matched and not kept: no thread (so no thread-pool rows and no
per-thread key split), no session. No duration, bytes or count.

### D5 — one level-map mechanism

The word-to-level map is data on the entry, applied by one transform. The
Workgroup Manager entry's letter map moves onto the same mechanism in the same
change; its existing scenarios and samples prove it reads as before.

## Contracts

- **C1.** A connector log binds its entry by content alone, from any file name,
  under the entry's own name in the legend, `--help formats`, `-lf` and the
  `format:` key.
- **C2.** The stamp is read to the fraction written, as wall-clock time, with no
  zone conversion. A connector line and an access-log line of the same host in the
  same second fall in the same bucket.
- **C3.** The level word arrives as its vocabulary name (D2); the row's category,
  colour and order are the vocabulary's.
- **C4.** The message row is `[LEVEL] [function] message` (D4); one connector
  failure is one row with its count.
- **C5.** ERROR and EMERGENCY lines are failures; nothing is a success (D3).
- **C6.** A line in a shape no entry reads is counted unmatched and shown in the
  detection report, never misread.
- **C7.** Beside an access log, one timeline and one category table, both formats
  in the legend (F4).
- **C8.** The Workgroup Manager entry reads exactly as before (D5).
- **C9.** Nothing else moves except the registry inventory counts and order.

## Acceptance criteria

Owning harnesses: `tests/validate-format-detection.sh`,
`tests/validate-format-registry.sh`, `tests/validate-log-level-vocabulary.sh`.
Fixtures are committed under `tests/fixtures/format-detection/` as `.txt`, scrubbed
(addresses to private placeholders, worker names `tomcatN`, ids `NO-ID`, counts
kept), one per entry, each covering every message family its shape carries.

- [ ] **AC1 (C1).** Each entry's fixture, staged under a connector-style file name,
      reports its own `format:`, every line matched, `unregistered_levels: -`,
      `event_ledger: no`, `metrics_observed: no`. *Assertable:* one scenario per
      entry (`-bs 1440 -oe -n 1`).
- [ ] **AC2 (C1, C6).** The held shape's fixture staged under a neutral name
      (`app.txt`) binds the same entry: content alone, no filename evidence.
      *Assertable:* scenario in the detection harness.
- [ ] **AC3 (D1 samples).** Every entry's samples produce their expected records
      (category, object = function, empty thread, message) and outcomes, or the
      build dies naming the entry. *Assertable:* D24 gates 1 and 2 on every run,
      plus a sabotage proof recorded under *Implementation*.
- [ ] **AC4 (C2).** `-st` one millisecond after a known line's stamp excludes
      exactly the lines at or before it. *Assertable:* `-V filter-summary`
      `excluded_time_window` and `included`, in the detection harness.
- [ ] **AC5 (C7).** The held shape's fixture beside a scrubbed access fixture whose
      413s and 503s sit at the connector lines' seconds: a one-second window at
      each of three seconds includes exactly the connector line and its access
      line, and the legend reads `1=access_common_duration,2=apache_mod_jk`.
      *Assertable:* scenario in the detection harness.
- [ ] **AC6 (C3, D2).** Each mapped word arrives as its vocabulary name, and a
      word outside the map appears in `unregistered_levels` with its count.
      *Assertable:* scenario in the vocabulary harness; lines for words other than
      `error` are synthetic and marked so in the manifest.
- [ ] **AC7 (C1).** `--help formats` lists each entry under Other formats, not an
      event ledger, with the failure rule and no success rule. *Assertable:*
      existing `declared-levels-in-help` scenario extended.
- [ ] **AC8 (C1).** `-lf <name>` seats exactly that entry and binds its fixture; a
      mistyped `-lf` lists the entries among the known formats. *Assertable:*
      `format-pin` scenario extended.
- [ ] **AC9 (C9).** `scanned_entries`, `scan_slots`, `entries` and `static_order`
      move by the number of entries added, each with no ancestors. *Assertable:*
      `inventory`, `structure` and `scan-telemetry` scenarios updated in the same
      commit as the counts in the registry record.
- [ ] **AC10 (C8, D5).** The Workgroup Manager scenarios pass unchanged.
      *Assertable:* `wgm-client` and `wgm-client-localtime`.
- [ ] **AC11.** No ` at <file> line <N>` on stderr in any scenario. *Assertable:*
      `tests/lib/runtime-warnings.sh`.
- [ ] **AC12 (C7).** Rendered on the held files: the 413 day shows ERROR 1, 8, 14,
      20, 25, 14, 8, 4, 2, 6 in the hours 11 and 14 to 22 beside each hour's 4xx
      with both formats in the legend; the 503 burst shows ERROR 110, 2,258, 9 at
      11:50 to 11:52 beside the 503s and none beside the 500 storm.
      *Unassertable, visual:* looked at once, figures recorded under
      *Implementation* without paths.

## Gate

The scan sub gains one slot per entry, which every line of no known format also
tries. Full harness suite plus the `single-day-access-log-standard` before/after
benchmark, the before captured on the base commit. No `-V` section or key changes.
No change to `--help` text beyond the generated formats list, none to
`docs/usage.md`. Release note: *Read Apache mod_jk connector logs, so connector
errors sit on the timeline beside the access log's 413 and 503 responses.*

## Implementation

Not started.
