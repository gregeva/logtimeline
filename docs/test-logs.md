# Test Log Files

The `logs/` directory contains sample log files for testing. **Always use these known files for testing - do not search for log files.**

## Directory Structure
```
logs/
├── AccessLogs/              # HTTP access logs (duration, bytes, status)
├── Codebeamber/             # Codebeamer access logs
├── GC/logs-gc/              # JVM G1 garbage-collection logs
├── UDM/                     # User-defined-metric logs (pattern + CSV modes)
├── WGM/                     # SolidWorks Workgroup Manager client logs
├── MethodServer/            # Windchill Method Server / Background Method Server logs
├── IntegrationRuntimeLogs/  # ThingWorx Integration Runtime logs (yyyy-dd-MM dates)
└── ThingworxLogs/           # ThingWorx application logs
    ├── CXS/                 # ThingWorx Connection Server logs
    └── CustomThingworxLogs/ # Custom ScriptLogs with durationMS
```

---

## AccessLogs/ - HTTP Request Logs (duration, bytes, status)

| File | Server | Latency Unit | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|---|---|
| `ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | Apache HTTP Server 2.x | microseconds (%D) | duration, bytes | 98KB | 677 | Apache HTTP2 with microsecond latency (the `-FULL` sibling is 658KB) |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 277MB | 1,430,678 | Primary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 220MB | 1,133,132 | Secondary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 148MB | 761,698 | Smaller Tomcat 9 access log test |
| `localhost_access_log.2025-03-21.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 2.6MB | 22,264 | **CORRUPT — do not use for clean-output testing.** Contains concatenated records (two log lines merged on one line), so field captures pick up fragments of the following record (e.g. an IP fragment where the duration belongs). Useful only as adversarial malformed input; ltl treats such non-numeric duration captures as unobserved (#341, #345). No harness uses this file (the regression/ticks fixture is derived from the 2025-05-07 corpus via `tests/lib/fixtures.sh`) |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 1.0MB | 5,000 | 5k-line slice from 05-05 log; the configuration-class fixture for `tests/validate-index-read-back.sh`, `validate-histogram-bin-counters.sh`, `validate-format-detection.sh`, `validate-statistics-demand.sh`, `validate-numeric-criteria-notices.sh`. Regenerate via `tests/fixtures/regenerate-index-readback-fixtures.sh` |
| `tests/fixtures/tomcat-access-duration-spread.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 52KB | 434 | Deterministic synthetic fixture for `tests/validate-duration-display.sh`: 12 generic endpoints over a 14.5 h span with duration values chosen to render every cell class (0ms, 1ms, 58ms, 166ms, 1s, 1.4s, 5.5s). TEST-NET addresses, no real hosts or paths. Regenerate via `tests/duration-display/generate-fixture.py` |
| `tests/fixtures/tomcat-access-single-sample-keys.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 12 | The first 12 lines of `tomcat-access-duration-spread.txt`: twelve distinct endpoints, one request each, so every message key carries exactly one duration and none reaches the n ≥ 2 (`cv`, `stddev`) or n ≥ 4 (shape) sort-eligibility floors. Exercises the post-walk unsatisfiable-sort fallback in `tests/validate-statistics-demand.sh` |
| `tests/fixtures/http-status-families.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 10 | Two lines per HTTP status family (1xx–5xx) over ten consecutive seconds, three of them on a `/store/orders` path so a highlight produces a highlighted twin for 2xx, 4xx and 5xx. The category-name fixture for `tests/validate-category-names.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/category-contribution-skew.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 4KB | 53 | Four HTTP status families in deliberately unequal proportions — 40 / 8 / 4 / 1 lines — over one minute, so the contribution bars drawn across the category rows have four distinct lengths at every scale and a bar measured against the wrong reference cannot land on the right length by chance. The single 5xx line is the tail case the logarithmic scale exists for. The fixture for `tests/validate-summary-contribution-bar.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/profile-weekend-fold.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 5 | One line per day, Wednesday to Sunday, at the same time of day, so a `-pr workday` fold drops exactly the two weekend lines. The profile-fold fixture for `tests/validate-filter-summary.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/bucket-size-units.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 4 | One line per day, four days, carrying one duration per display-ladder step above a day (10 days, 45 days, 400 days) and one value of 500 that reads as 500 ns under `-du ns`. The display-ladder fixture for `tests/validate-bucket-size-units.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/classification-states.txt` | classification verification format (synthetic, pin with `-lf classification_verification`) | milliseconds | duration | 2KB | 16 | Sixteen lines over four days carrying every classification state: all-success, all-failure, all-conflict and all-unclassified rows, a success/failure row and a success/unclassified row (both mixed), a near-identical pair that consolidates under `-g`, and one day each where only a conflict or only a qualifying-source unclassified line withholds the bucket's percentages. Unrecognised by detection; the producer for `tests/validate-classification-states.sh`. No real hosts or paths |
| `localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` | Tomcat 9 | milliseconds (%D, fractional, three places) | duration, bytes, thread, session | 118MB | 517,684 | The common-plus-duration-thread-session shape (`access_common_duration_thread_session`): a fractional millisecond duration, the thread name on every line, a session id on a third to four fifths of the lines and `-` elsewhere. Thread-session shape specimen; 198 malformed-request lines carry the literal `null` as their thread |
| `access.log-20260609` | nginx (custom `log_format`) | none read | bytes | 37MB | 219,933 | Combined format plus a quoted forwarded-for and six `key="value"` pairs (a decimal-seconds request time among them). Binds `access_combined`; no duration is read from a custom nginx format. Two lines carry a populated remote user |
| `really-big/*` | Tomcat 9 (thirty days) | milliseconds (%D); fractional on the later shape | duration, bytes; thread and session on the later shape | 8.5GB | — | Really big access logs from five servers over 30 days (`-0` to `-4`, thirty files each). The shape changes on one date on every server: the common-plus-duration shape (`access_common_duration`, integer milliseconds, 90 files) becomes the thread-session shape (`access_common_duration_thread_session`, fractional milliseconds, 60 files) |

**Format**: the access-log family (`access_common`, `access_common_duration`, `access_common_duration_thread_session`/`_us`, `access_combined`, `access_combined_duration`, `access_common_duration_bracketed`): the Common Log Format with the shape's trailing fields; a bare `%D` is read in milliseconds (Tomcat 6-9) unless `-du us` names the microsecond producers (Apache HTTP Server, Tomcat 10.1+); nothing on the line tells them apart
```
# Apache HTTP Server 2.x - microseconds
127.0.0.1 - - [22/Jan/2026:08:49:51 +0000] "GET /path HTTP/1.1" 200 209 173542

# Tomcat 9 - milliseconds
10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /path HTTP/1.1" 200 261 1
```
Fields: IP, -, -, [timestamp], "method path protocol", status_code, bytes, duration

**Note**: Apache HTTP Server uses `%D` for microseconds, while Tomcat 6-9 uses `%D` for milliseconds, and the two line shapes are identical: both bind `access_common_duration`, which reads the value in milliseconds. Nothing on the line tells the producers apart, so a microsecond file is read with `-du us`; without it, durations from the Apache specimen read a thousand times too large.

---

## WGM/ - SolidWorks Workgroup Manager Client Logs

Client-side diagnostic logs from PTC Workgroup Manager for SolidWorks (WGM). One shared structured format across three filenames, each written by a different WGM client subsystem: `genlwsc.log.1` (network/streaming engine), `uwgm_client.log.1` (top-level UWGM client/UI process), and `uwgm.log.1` (the CAD-process-scoped log, nested under a `Log_PROE_*` folder — the richest source, since it's scoped to one CAD session). Four capture sets are present: a large-assembly retrieval captured in both Normal and Lightweight SolidWorks modes, a pair of sessions from one retry-heavy incident class, a pair of sessions captured over a slow connection, and a single-file network-thread test.

**Two timestamp forms.** The producer writes the timezone as its header's `use_local_time` setting dictates: `use_local_time NO` yields a `Z` suffix (the first two sets), `YES` yields a numeric offset with a **non-zero-padded hour** — `+2:00`, `+0:00` (the last two sets). Both forms are recognised; the zone is matched and discarded, so the timeline is the wall clock the file states.

| Folder | Scenario | Files | Lines (genlwsc / uwgm_client / uwgm) | Use Case |
|---|---|---|---|---|
| `session-retry-incident/Session_1_1/` | WGM session with heavy indirect-download retry activity | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 5,842 / 474,278 / 232,032 | Primary WGM format development/testing session |
| `session-retry-incident/Session_2/` | Second WGM session, same class | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 4,971 / 465,746 / 194,313 | Second WGM session for cross-session comparison |
| `large-assembly-retrieval/Normal Mode/` | Large-assembly retrieval, Normal (non-lightweight) SolidWorks mode | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 8,769 / 842,928 / 110,384 | Largest uwgm_client.log.1 in the set; dense single-session Content Manager VFS activity |
| `large-assembly-retrieval/Lightweight Mode/` | Same assembly, Lightweight SolidWorks mode | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 7,766 / 155,541 / 31,756 | Smallest complete triple; good for quick format iteration |
| `2k-assembly-slow-connection-test/1/` | 2k-component assembly retrieved over a slow connection, session 1 | genlwsc.log.1, Log_PROE_*/uwgm.log.1 (no uwgm_client.log.1) | 144,399 / — / 3,064,487 | Local-offset (`+2:00`) timestamps; 663MB uwgm.log.1. Download-outcome analysis: `$<ContentDownloadFinish>` records carrying `Status=` |
| `2k-assembly-slow-connection-test/2/` | Same assembly and connection class, session 2 | genlwsc.log.1, Log_PROE_*/uwgm.log.1 (no uwgm_client.log.1) | 396,751 / — / 3,400,878 | Largest single WGM file in the set (752MB); the two sessions together carry 17,359 download-finish records across five status values, including terminal `FAIL` |
| `2026-04-30_JapanEast_Test3-12networkThreads/` | Single-file network-thread configuration test | uwgm.log.1 only | — / — / 137,140 | Smallest failure-rich file (37MB): 48,580 download-finish records, 27,542 of them `RETRY`, each with a matching `E` line. Quick iteration on download-outcome work |

**Format**: Self-describing structured log — each file opens with a `$default: $generic:` header block declaring its own schema (`columns`, `columns_sep`, `date_format`, `time_format`, `time_precision`, `log_base_name`), followed by data lines matching that schema.
```
2025-10-29T10:56:55.850Z: C: P8254: T248c: $default: $generic: columns "date time tz msgtype logid tid area message"
2025-10-29T10:56:55.850Z: C: P8254: T248c: $default: $generic: columns_sep ": "
2025-10-29T10:56:55.850Z: C: P8254: T248c: $default: $generic: time_precision 1000
2025-10-29T10:56:53.239Z: X: Pa5b4: T8570: UWGM: UWGM created
2025-10-29T10:56:54.392Z: I: Pa5b4: T8570: uwgmclnt.clntpref_read.prefmgr_addread.pref_file_reader: WWGM_PREFERENCES: Reading preferences from file: C:\Program Files\PTC\wgm 13.1.0.0\wgmclient.ini
```
Fields: `date`(T)`time`(ms precision) followed by either `Z` or a numeric offset such as `+2:00`/`+0:00` (combined ISO-8601-style timestamp; the offset form is not zero-padded, so it is not strictly ISO-8601), `msgtype` (single letter, ten values across the set: C/D/E/F/I/S/T/W/X/Y — config/debug/error/finish/info/start/trace/warn/create/destroy), `logid` (process id, hex-prefixed `P`), `tid` (thread id, hex-prefixed `T`), `area` (dotted component path; session and transaction areas carry `#` qualifiers such as `act#…` and `srvtxn#N`), `message` (free text, may itself contain `: `-delimited sub-fields).

**Structure**: every line in every file matches the one shape — no continuation lines, no blank lines, ASCII throughout. A minority of trace messages (HTTP response headers echoed into the log) end in a carriage return, which the line reader strips. The `uwgm.log.1` header declares `log_base_name "uwgm_client"`, so the in-file name does not distinguish it from `uwgm_client.log.1` — only the file name does. `D` dominates every file (80–90% of lines); `X`/`Y` and `S`/`F` come in matched create/destroy and start/finish pairs on the same `area`. The two later sets carry no `uwgm_client.log.1`, and their session folders also hold CAD-side logs written by other producers in other formats (`xtop.log.1`, `renderlog.log.N`, `creoagent.log.1`, `js_console_debug_*.log.1`, `mcp_applet_async.log.1`, `list_nd.log`) plus thousands of CAD payload artifacts under `Streams/` and `cip_nd/` — none of these is a WGM-format log, so a recursive selection over a session folder picks up files this entry does not describe.

**Structured event records.** A subset of lines carries a tagged record in the message: `IndexLogging: Ver-0.1 <id>$<Tag>…</Tag>`. Two tag families report outcomes and are the basis of any success/failure reading of this format: `$<ContentDownloadStart>`/`$<ContentDownloadFinish>` (per download attempt, with `Attempt=N`, `Content Size=` and a `Status=` of `UWGM_DOWNLOAD_COMPLETION_STATUS_{SUCCESS,ALREADY_CACHED,RETRY,RETRY_IMMIDIATELY,FAIL}`, emitted at `D`), and `$<ActionState>` (per user-level action, values `started` and `finished: SUCCEEDED`, emitted at `I`). No failed `$<ActionState>` value occurs in any set held here.

**ltl format**: `windchill_workgroup_manager` — one entry for all three filenames; the letters become the `DEBUG`/`ERROR`/`INFO`/`TRACE`/`WARN` levels plus the `CONFIG`/`CREATE`/`DESTROY`/`START`/`FINISH` categories. Occurrences only (no duration, bytes or count at the line level). The committed fixture `tests/fixtures/format-detection/wgm-client.txt` is a scrubbed 44-line slice of an `uwgm_client.log.1`.

---

## MethodServer/ - Windchill Method Server / Background Method Server Logs

Server-side `log4j` diagnostic logs from Windchill Method Server and Background Method Server processes. One shared log4j pattern layout across the service family (`MethodServer`, `BackgroundMethodServer`, `BackgroundMethodServerCAD`, `BackgroundMethodServerESI`) — the service shows only in the file name and in startup lines. Two capture sets are present: a four-tier set covering all four service names, and a multi-node set spanning two days of rotation.

| Folder | Scenario | Files | Total Size | Lines | Use Case |
|---|---|---|---|---|---|
| `queue-worker-tiers/18Jul2025_QA_BGMS_Logs/` | App1–4 tiers, all four service names in one set | 18 (12 MethodServer, 4 BackgroundMethodServer, 1 CAD, 1 ESI) | 10MB | 83,001 | Full family coverage at manageable size; the ESI file is 98% stack-trace continuation lines (1,356 records in 65,088 lines), the others 66–73% records |
| `multi-node-prod/04-05Aug2025/` | Node1–4, two days, daily rotation (`.YYYY-MM-DD_N` suffix after the extension) | 48 (45 MethodServer, 3 BackgroundMethodServer) | ~410MB | 2,360,942 | Large multi-node, multi-rotation set; ~78% records (1.84M), 96–99% of them carrying a user token; rolled names exercise the filename-date cross-check |
| `multi-node-prod/06Aug2025/` | Node2–4, one unrolled file per node | 4 (MethodServer) | ~21MB | 110,386 | Smaller single-rotation slice of the same set (88% records) |
| `tests/fixtures/message-control-characters-unmatched.txt` | Two matched lines around one space-led continuation line no format recognises | 1 | 270B | 3 | The one-unmatched-line fixture for `tests/validate-message-control-characters.sh` and the unmatched scenario of `tests/validate-filter-summary.sh` (read 3, unmatched 1, included 2) |
| `tests/fixtures/log-level-outside-vocabulary.txt` | Two INFO lines around one line whose level, NOTICE, the format matches but the log-level vocabulary does not carry | 1 | 250B | 3 | The vocabulary-rejection fixture for `tests/validate-filter-summary.sh`: the NOTICE line is matched, then dropped at the category gate |

**Format**: `windchill_method_server` — `log4j` pattern layout `%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%t] %c %x - %m`, one line per record, no self-describing header (unlike WGM's format above). Occurrences only: no line-level duration, bytes or count.
```
2025-07-18 04:46:41,354 INFO  [main] wt.method.server.startup  - Starting BackgroundMethodServer
2025-07-18 06:28:01,115 ERROR [ajp-nio-127.0.0.1-8010-exec-2312] com.ptc.windchill.uwgm.proesrv.rrc.RequestResultCache user01 - UwgmObjectFactory.createPartIteration :: Unsupported PartType: RAW_MATERIAL
2025-07-18 04:52:55,260 WARN  [JMX Monitor ThreadGroup<main> Executor Pool [Thread-21]] wt.jmx.notif.methodContextGauge  - Time=2025-07-18 04:52:55.257 +0000, Name=MethodContextsGaugeNotifier
```
Fields: `date time,ms` (space-separated, millisecond precision, no explicit timezone — local server time), `LEVEL` (`INFO`/`ERROR`/`WARN`/`FATAL`/`TRACE`, padded to five characters), `[thread]` (bracketed thread name — `main`, an app-server worker id like `ajp-nio-127.0.0.1-8010-exec-2312`, or a nested-bracket pool name like `JMX Monitor ThreadGroup<main> Executor Pool [Thread-21]`), `logger` (dotted Java category), then the user-context slot before the ` - ` separator — always present, a user token on request-handling lines and empty on startup/monitor lines (which is why those show two spaces before ` - `) — then free-text `message` (may be empty).

**Filenames**: `<Service>-<yyMMddHHmm>-<pid>-log4j.log` (process start time and pid); daily rotation appends `.YYYY-MM-DD_N` after the extension, and the roll date is the content date.

**Note**: every file carries multi-line continuation records — tab-indented `\tat ...` frames, unindented `Nested exception is:` / `Caused by:` lines, multi-line property dumps and version tables after a startup line, and blank lines — none carrying a leading timestamp. They are unmatched lines (same treatment as ThingWorx's `ScriptErrorLog`); `BackgroundMethodServerESI` is the extreme case. Committed fixture: `tests/fixtures/format-detection/windchill-method-server.txt` (scrubbed, 21 records + 30 continuation lines).

---

## Codebeamber/ - Codebeamer Access Logs

| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `codebeamer_access_log.2025-10-29.txt` | duration, bytes, count | 83KB | 741 | Codebeamer format testing |

**Format**: Apache-style with duration in brackets
```
127.0.0.1 - - [29/Oct/2025:08:03:31 +0000] "GET /hc/ping.spr HTTP/1.1" 200 112 [293ms] [0.293s]
```

---

## GC/logs-gc/ - JVM G1 Garbage-Collection Logs

Unified-logging (JDK 9+) G1 logs, `[info]` level throughout (no `[debug]`/`[trace]` detail in any file). Pause lines (`Pause Young`/`Full`/`Remark`/`Cleanup` with heap `N->N(M)` and pause ms) match the GC format; the remainder (`Concurrent Mark Cycle`, `Using G1`, …) do not — in the largest file ~71% of lines are pause lines.

| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `gc-twx01-twx-thingworx-2.out.8` | duration (pause), heap delta | 79MB | 781,118 | Largest GC log; best single file for scale testing |
| `gc-twx01-twx-thingworx-3.out.6` | duration (pause), heap delta | 62MB | 599,346 | Second-largest GC log |
| `gc-twx01-twx-thingworx-0.out.6` | duration (pause), heap delta | 50MB | 495,015 | Third-largest GC log |
| (many smaller rotations) | duration (pause), heap delta | 1.4KB–33MB | — | Rotated GC logs from 5 servers |

**Format**: JVM unified logging
```
[2025-04-05T11:10:47.867+0000][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 2433M->66M(49152M) 18.406ms
```

---

## ThingworxLogs/ - ThingWorx Application Logs

All ThingWorx logs use this standard format:
```
2025-05-05 00:00:00.006+0000 [L: ERROR] [O: c.p.a.u.JobPurgeScheduler] [I: ] [U: SuperUser] [S: ] [P: ] [T: ThreadName] Message
```
Fields: timestamp [L: level] [O: origin] [I: instance] [U: user] [S: session] [P: process] [T: thread] message

### ApplicationLog (General platform activity)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ApplicationLog.2025-05-05.0.log` | occurrences only | 85MB | 479,904 | Large Linux ApplicationLog |
| `ApplicationLog.2025-05-06.0.log` | occurrences only | 6.5MB | 23,604 | Medium ApplicationLog |
| `ApplicationLog.2025-12-12.282-Windows.log` | occurrences only | 10MB | 608 | Windows ApplicationLog |
| `ApplicationLog.log` | occurrences only | 5.8MB | 22,904 | Current ApplicationLog |
| `ApplicationLog-improperlyRead.log` | occurrences only | 468B | 2 | Edge case - malformed reads |
| `HundredsOfThousandsOfUniqueErrors.log` | occurrences only | 101.7MB | 288,025 | Hundreds of thousands of unique error messages (group-similar) |

### ScriptLog (Script execution logs)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ScriptLog.2025-05-05.0.log` | occurrences only | 13MB | 36,973 | Standard ScriptLog |
| `ScriptLog.2025-05-06.0.log` | occurrences only | 15MB | 41,559 | Standard ScriptLog |
| `ScriptLog.2025-12-17.0.Rolex.log` | occurrences only | 1.6MB | 6,771 | Basic ScriptLog test |
| `ScriptLog.log` | occurrences only | 4.4MB | 8,600 | Current ScriptLog |

### ErrorLog (Error-level messages)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ErrorLog.2025-05-05.1.log` | occurrences only | 61MB | 350,192 | Large error log (auth failures, etc.). Every line starts with a timestamp — no stack-trace/continuation lines |
| `ErrorLog.2025-05-06.0.log` | occurrences only | 3.3MB | 16,020 | Medium error log |
| `ErrorLog.log` | occurrences only | 3.7MB | 20,217 | Current error log |

### SecurityLog (Security events)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `SecurityLog.2025-05-05.1.log` | occurrences only | 70MB | 382,097 | Large security log (nonce rejections) |
| `SecurityLog.2025-05-06.0.log` | occurrences only | 3.0MB | 15,751 | Medium security log |
| `SecurityLog.log` | occurrences only | 3.6MB | 20,174 | Current security log |

### ScriptErrorLog (Script-specific errors)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ScriptErrorLog.2025-05-05.0.log` | occurrences only | 14MB | 114,610 | Script error analysis. ~74% of lines are stack-trace/continuation lines (no leading timestamp) — best no-match-population source |
| `ScriptErrorLog.2025-05-06.0.log` | occurrences only | 14MB | 111,068 | Script error analysis (similarly continuation-heavy) |
| `ScriptErrorLog.log` | occurrences only | 2.5MB | 5,250 | Current script errors |

### DatabaseLog (Database operations)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `DatabaseLog.2025-05-05.0.log` | occurrences only | 700KB | 2,136 | Database error tracking |
| `DatabaseLog.2025-05-06.0.log` | occurrences only | 693KB | 2,107 | Database error tracking |
| `DatabaseLog.log` | occurrences only | 29KB | 89 | Current database log |

### AuthLog (Authentication events)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `AuthLog.2025-05-05.0.log` | occurrences only | 324KB | 1,296 | SAML/SSO authentication events |
| `AuthLog.2025-05-06.0.log` | occurrences only | 257KB | 1,021 | Authentication events |
| `AuthLog.log` | occurrences only | 167KB | 747 | Current auth log |

### ConfigurationLog (Configuration changes)
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ConfigurationLog.2025-05-05.0.log` | occurrences only | 30KB | 169 | Configuration tracking |
| `ConfigurationLog.2025-05-06.0.log` | occurrences only | 31KB | 174 | Configuration tracking |
| `ConfigurationLog.log` | occurrences only | 31KB | 174 | Current configuration log |

### Other ThingWorx Logs
| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `CommunicationLog.2025-05-06.0.log` | occurrences only | 190B | 1 | Communication events (minimal) |
| `AkkaCommunicationLog.log` | occurrences only | 2.2KB | 3 | Akka communication events |

### CXS/ - ThingWorx Connection Server
| File | Format | Size | Lines | Use Case |
|---|---|---|---|---|
| `cxserver.1-16.log` … `cxserver.1-26.log` | `connection_server_standard` (`yyyy-MM-dd`) | 105MB each | ~1,000,000 each | Vert.x/logback platform log; multi-line payloads (about half the lines are continuation lines); the Connection Server member of the `connection_server` variant group |

---

## IntegrationRuntimeLogs/ - ThingWorx Integration Runtime
| File | Format | Size | Lines | Use Case |
|---|---|---|---|---|
| `IntegrationRuntime-46b44bb3-….log` | `integration_runtime_standard` (`yyyy-dd-MM`) | 695KB | 5,416 | Byte-identical line shape to the Connection Server but dates are day-first; the only known true positive for the date-layout transposition (#385). Detection decides it from the sampled content (day tokens > 12) even when renamed; ten runtime sessions, 2023-06 → 2025-01 |
| `integrationRuntime-logback.xml` | — | 466B | — | The producer's logback encoder configuration (shows the `yyyy-dd-MM` pattern) |

---

## ThingworxLogs/CustomThingworxLogs/ - ScriptLogs with Full Metrics

These logs contain `durationMS=`, `result bytes=`, and `result count=` fields enabling all metric types for analysis and heatmaps.

| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ScriptLog-DPMExtended-clean.log` | duration, bytes, count | 29MB | 122,808 | Cleaned DPM ScriptLog - ideal for all heatmap types |
| `ScriptLog-DPMExtended-clean-5k.log` | duration, bytes, count | 1.1MB | 5,000 | 5k-line slice from DPMExtended-clean; used by `tests/validate-index-read-back.sh`, `validate-heatmap-palette.sh` and the ScriptLog runs of `validate-regression.sh` / `capture-regression.sh` (at `-bs 1`). Regenerate via `tests/fixtures/regenerate-index-readback-fixtures.sh` |
| `ScriptLog.2025-04-09.1.log` | duration, bytes, count | 98MB | 252,640 | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.2.log` | duration, bytes, count | 98MB | 254,208 | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.3.log` | duration, bytes, count | 98MB | 271,552 | Large ScriptLog with full metrics |
| `tests/fixtures/numeric-highlight-boundary.txt` | duration, bytes, count | 3KB | 19 | Synthetic ScriptLog lines placing each metric below, at and above the bounds of a numeric criterion, plus one line per metric carrying no value for it and one line inside every bound. The boundary fixture for `tests/validate-numeric-criteria-notices.sh`; `-dmin 100 -dmax 200` keeps exactly four lines, the numeric scenario of `tests/validate-filter-summary.sh` |
| `ScriptLog.2025-04-09.4.log` | duration, bytes, count | 72MB | 320,222 | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-10.0.log` | duration, bytes, count | 98MB | 431,777 | Large ScriptLog with full metrics |
| `ScriptLog.GetComplexPlotByIndex.log` | duration, bytes, count | 739KB | 2,992 | Specific service analysis |
| `ScriptLog.log` | duration, bytes, count | 54MB | 236,497 | ScriptLog with full metrics |


---

## /UDM - User Defined Metric Test Logs (system_cpu_total, bytes_sent, bytes_received, latency_ms)

| File | Application | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|---|
| `rea-assets-5402_-TW_SSL_READ-Read_0_bytes-trace_logs.log` | ThingWorx Edge C SDK | TSV formatted metrics Recv-Q=0 Send-Q=0 bytes_sent=6185 bytes_retrans=347 bytes_acked=5839 bytes_received=8373 | 2.1 MB | 25,350 | For UDM/user defined metrics testing in pattern mode. Use include filter for text "CONN_MON statistics" to target the relevant lines |
| `connection-server-custom-metrics.csv` | Custom Monitoring Script | Various CSV formatted system metrics: system_cpu_total, tcp_inuse, tcp_established, tcp_timewait, ctx_switches, ctx_nonvoluntary, tcp_delayed_acks | 29 KB | 119 | For UDM/user defined metrics testing in CSV mode |
| `results_data_idonly-timestampMs.csv` | Custom TCP Packet Data Analysis | Various CSV formatted system metrics: latency_ms, request_size, response_size, request_id, stream | 9.8 MB | 166,912 | For UDM/user defined metrics testing in CSV mode |

**Format**: ThingWorx Edge SDK agent logs with embedded TCP connection statisits (rea-assets-5402_-TW_SSL_READ-Read_0_bytes-trace_logs.log)
```
INFO 2025-09-23 15:58:05,021 CONN_MON statistics: Local=10.244.35.50:49664 Peer=193.58.155.1:https sev=9 Recv-Q=0 Send-Q=0 cubic=1 wscale_sndr=13 wscale_rcvr=7 rto=248 rtt=46.941 rttvar=15.761 ato=40 mss=1448 pmtu=1500 rcvmss=1428 advmss=1448 cwnd=4 ssthresh=7 bytes_sent=6185 bytes_retrans=347 bytes_acked=5839 bytes_received=8373 segs_out=144 segs_in=196 data_segs_out=129 data_segs_in=71
```
**Format**: Generic CSV File starting with a timestamp, followed by a variable set of metric columns (results_data_idonly-timestampMs.csv)
```
request_timestamp,response_timestamp,latency_ms,request_size,response_size,request_id,stream
1771078373.207929,1771078373.217339,9.410143,60,17,1,0
1771078373.237935,1771078373.247892,9.956837,61,2911,2,0
1771078373.306736,1771078373.325041,18.305063,38,17,3,0
1771078373.333200,1771078373.343861,10.661125,459,340,4,0
1771078373.361570,1771078373.369284,7.714033,239,17,5,0
```

---

## Quick Test Commands

```bash
# Duration heatmap (access logs - best for latency analysis)
./ltl -hm duration logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt

# Bytes heatmap (access logs - response size distribution)
./ltl -hm bytes logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt

# Count heatmap (any log - message frequency distribution)
./ltl -hm count logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log

# Duration heatmap from ThingWorx ScriptLogs with durationMS
./ltl -hm duration logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log

# Standard bar graph (any log)
./ltl -n 5 logs/ThingworxLogs/ApplicationLog.2025-12-12.282-Windows.log

# Quick test with small access log
./ltl -n 10 logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt

# Error analysis
./ltl -n 20 logs/ThingworxLogs/ErrorLog.2025-05-05.1.log

# Security event analysis
./ltl -n 10 logs/ThingworxLogs/SecurityLog.2025-05-05.1.log

# Codebeamer access log
./ltl -hm duration logs/Codebeamber/codebeamer_access_log.2025-10-29.txt
```

## Logs by Use Case

| Use Case | Recommended Log Files |
|---|---|
| **Duration/latency heatmap** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Bytes/response size analysis** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Count/frequency analysis** | Any log file |
| **All three metrics (duration, bytes, count)** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Error analysis** | `ThingworxLogs/ErrorLog.*`, `ThingworxLogs/ScriptErrorLog.*` |
| **Security events** | `ThingworxLogs/SecurityLog.*`, `ThingworxLogs/AuthLog.*` |
| **Database issues** | `ThingworxLogs/DatabaseLog.*` |
| **GC pause analysis** | `GC/logs-gc/gc-twx01-twx-thingworx-2.out.8` (largest) |
| **Stack-trace/continuation (no-match) lines** | `ThingworxLogs/ScriptErrorLog.2025-05-05.0.log`, `ScriptErrorLog.2025-05-06.0.log`, `MethodServer/queue-worker-tiers/.../BackgroundMethodServerESI-*-log4j.log` |
| **Quick tests (small files)** | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt`, `Codebeamber/*`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` |
| **Adversarial/malformed input** | `AccessLogs/localhost_access_log.2025-03-21.txt` (corrupt concatenated records — see AccessLogs table note) |
| **Large file stress tests** | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.*.log` |
