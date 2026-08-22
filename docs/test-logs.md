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
└── ThingworxLogs/           # ThingWorx application logs
    └── CustomThingworxLogs/ # Custom ScriptLogs with durationMS
```

---

## AccessLogs/ - HTTP Request Logs (duration, bytes, status)

| File | Server | Latency Unit | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|---|---|
| `ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | Apache HTTP Server 2.x | microseconds (%D) | duration, bytes | 658KB | 677 | Apache HTTP2 with microsecond latency |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 277MB | 1,430,678 | Primary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 220MB | 1,133,132 | Secondary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 148MB | 761,698 | Smaller Tomcat 9 access log test |
| `localhost_access_log.2025-03-21.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 2.6MB | 22,264 | **CORRUPT — do not use for clean-output testing.** Contains concatenated records (two log lines merged on one line), so field captures pick up fragments of the following record (e.g. an IP fragment where the duration belongs). Useful only as adversarial malformed input; ltl treats such non-numeric duration captures as unobserved (#341, #345). No harness uses this file (the regression/ticks fixture is derived from the 2025-05-07 corpus via `tests/lib/fixtures.sh`) |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 1.0MB | 5,000 | 5k-line slice from 05-05 log; used by `tests/validate-index-read-back.sh`. Regenerate via `tests/fixtures/regenerate-index-readback-fixtures.sh` |
| `really-big/*` | Tomcat 10 | milliseconds (%D) | duration, bytes | 8.5GB | — | Really big access logs from 4 servers over 28 days |

**Format**: Apache combined log with duration at end (units vary by server)
```
# Apache HTTP Server 2.x - microseconds
127.0.0.1 - - [22/Jan/2026:08:49:51 +0000] "GET /path HTTP/1.1" 200 209 173542

# Tomcat 9 - milliseconds
10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /path HTTP/1.1" 200 261 1
```
Fields: IP, -, -, [timestamp], "method path protocol", status_code, bytes, duration

**Note**: Apache HTTP Server uses `%D` for microseconds, while Tomcat uses `%D` for milliseconds. The detection regex is the same for both servers, so ltl resolves both to the same internal format (`tomcat_access_with_duration`) and assumes milliseconds. For Apache HTTP Server logs, pass `-du us` to convert microsecond durations into milliseconds for statistics; without it, durations are reported in the wrong unit by a factor of 1000. (Value-range autodetection is tracked separately by issues #17 and #23.)

---

## WGM/ - SolidWorks Workgroup Manager Client Logs

Client-side diagnostic logs from PTC Workgroup Manager for SolidWorks (WGM). One shared structured format across three filenames, each written by a different WGM client subsystem: `genlwsc.log.1` (network/streaming engine), `uwgm_client.log.1` (top-level UWGM client/UI process), and `uwgm.log.1` (the SolidWorks-process-scoped log, nested under a `Log_PROE_*` folder — the richest source, since it's scoped to one SolidWorks session). Two capture sets are present: a large-assembly retrieval captured in both Normal and Lightweight SolidWorks modes, and a pair of sessions from one retry-heavy incident class.

| Folder | Scenario | Files | Lines (genlwsc / uwgm_client / uwgm) | Use Case |
|---|---|---|---|---|
| `session-retry-incident/Session_1_1/` | WGM session with heavy indirect-download retry activity | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 5,842 / 474,278 / 232,032 | Primary WGM format development/testing session |
| `session-retry-incident/Session_2/` | Second WGM session, same class | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 4,971 / 465,746 / 194,313 | Second WGM session for cross-session comparison |
| `large-assembly-retrieval/Normal Mode/` | Large-assembly retrieval, Normal (non-lightweight) SolidWorks mode | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 8,769 / 842,928 / 110,384 | Largest uwgm_client.log.1 in the set; dense single-session Content Manager VFS activity |
| `large-assembly-retrieval/Lightweight Mode/` | Same assembly, Lightweight SolidWorks mode | genlwsc.log.1, uwgm_client.log.1, Log_PROE_*/uwgm.log.1 | 7,766 / 155,541 / 31,756 | Smallest complete triple; good for quick format iteration |

**Format**: Self-describing structured log — each file opens with a `$default: $generic:` header block declaring its own schema (`columns`, `columns_sep`, `date_format`, `time_format`, `time_precision`, `log_base_name`), followed by data lines matching that schema.
```
2025-10-29T10:56:55.850Z: C: P8254: T248c: $default: $generic: columns "date time tz msgtype logid tid area message"
2025-10-29T10:56:55.850Z: C: P8254: T248c: $default: $generic: columns_sep ": "
2025-10-29T10:56:55.850Z: C: P8254: T248c: $default: $generic: time_precision 1000
2025-10-29T10:56:53.239Z: X: Pa5b4: T8570: UWGM: UWGM created
2025-10-29T10:56:54.392Z: I: Pa5b4: T8570: uwgmclnt.clntpref_read.prefmgr_addread.pref_file_reader: WWGM_PREFERENCES: Reading preferences from file: C:\Program Files\PTC\wgm 13.1.0.0\wgmclient.ini
```
Fields: `date`(T)`time`(ms precision)`Z` (combined ISO-8601 UTC timestamp), `msgtype` (single-letter: C/D/I/T/W/X/Y — config/debug/info/trace/warn/create/destroy), `logid` (process id, hex-prefixed `P`), `tid` (thread id, hex-prefixed `T`), `area` (dotted component path), `message` (free text, may itself contain `: `-delimited sub-fields).

**Note**: No `ltl` format entry exists yet for this log type as of 2026-08-22 — tracked by #395 (blocked by #384).

---

## MethodServer/ - Windchill Method Server / Background Method Server Logs

Server-side `log4j` diagnostic logs from Windchill Method Server and Background Method Server processes. One shared log4j pattern-layout format across the MethodServer/BackgroundMethodServer filename family (including `BackgroundMethodServerCAD` and `BackgroundMethodServerESI` variants), differing by which Windchill process/queue-worker writes the file. Two capture sets are present: a QA-tier set covering all four filename variants, and a multi-node production set spanning several days of rotation.

| Folder | Scenario | Files | Total Size | Use Case |
|---|---|---|---|---|
| `queue-worker-tiers/18Jul2025_QA_BGMS_Logs/` | QA App1–4 tiers, all four filename variants present in one set | 18 files (MethodServer, BackgroundMethodServer, BackgroundMethodServerCAD, BackgroundMethodServerESI) | 10MB | Full variant coverage at manageable size; ESI files carry multi-line stack-trace continuation records (see Format note) |
| `multi-node-prod/04-05Aug2025/` | PROD Node1–4, multi-day rotation | 48 files (MethodServer, BackgroundMethodServer) | ~410MB | Large-scale, multi-node, multi-rotation production example |
| `multi-node-prod/06Aug2025/` | PROD Node2–4, single file per node | 4 files (MethodServer) | ~21MB | Smaller single-rotation slice of the same set |

**Format**: `log4j` pattern layout — one line per record, no self-describing header (unlike WGM's format above).
```
2025-01-27 14:22:28,785 INFO  [main] wt.method.server.startup  - Starting BackgroundMethodServer
2025-10-29 09:48:57,149 ERROR [ajp-nio-127.0.0.1-8010-exec-2312] com.ptc.windchill.uwgm.proesrv.rrc.RequestResultCache ITSALAN1 - UwgmObjectFactory.createPartIteration :: Unsupported PartType: RAW_MATERIAL
```
Fields: `date time,ms` (space-separated, millisecond precision, no explicit timezone — local server time), `LEVEL` (`INFO`/`ERROR`/`WARN`/`DEBUG` etc.), `[thread]` (bracketed thread name, e.g. `main` or an app-server worker id like `ajp-nio-127.0.0.1-8010-exec-2312`), `logger` (dotted Java class/category, e.g. `wt.method.server.startup` or `com.ptc.windchill.uwgm.proesrv.rrc.RequestResultCache`), an optional `user` token before the ` - ` separator (present on some lines, e.g. `ITSALAN1`, absent on others, e.g. startup lines), then free-text `message`.

**Note**: `BackgroundMethodServerESI` files contain multi-line stack-trace continuation records — an `ERROR` line ending in an exception class/message, followed by unindented `Nested exception is:` lines and tab-indented `\tat ...` frames, none carrying their own leading timestamp (same continuation-line shape ltl already handles for ThingWorx's `ScriptErrorLog`).

**Note**: No `ltl` format entry exists yet for this log type as of 2026-08-22 — tracked by #396 (blocked by #384).

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

---

## ThingworxLogs/CustomThingworxLogs/ - ScriptLogs with Full Metrics

These logs contain `durationMS=`, `result bytes=`, and `result count=` fields enabling all metric types for analysis and heatmaps.

| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `ScriptLog-DPMExtended-clean.log` | duration, bytes, count | 29MB | 122,808 | Cleaned DPM ScriptLog - ideal for all heatmap types |
| `ScriptLog-DPMExtended-clean-5k.log` | duration, bytes, count | 1.1MB | 5,000 | 5k-line slice from DPMExtended-clean; used by `tests/validate-index-read-back.sh`. Regenerate via `tests/fixtures/regenerate-index-readback-fixtures.sh` |
| `ScriptLog.2025-04-09.1.log` | duration, bytes, count | 98MB | 252,640 | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.2.log` | duration, bytes, count | 98MB | 254,208 | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.3.log` | duration, bytes, count | 98MB | 271,552 | Large ScriptLog with full metrics |
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
| **Stack-trace/continuation (no-match) lines** | `ThingworxLogs/ScriptErrorLog.2025-05-05.0.log`, `ScriptErrorLog.2025-05-06.0.log` |
| **Quick tests (small files)** | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt`, `Codebeamber/*`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` |
| **Adversarial/malformed input** | `AccessLogs/localhost_access_log.2025-03-21.txt` (corrupt concatenated records — see AccessLogs table note) |
| **Large file stress tests** | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.*.log` |
