# Test Log Files

The `logs/` directory contains sample log files for testing. **Always use these known files for testing - do not search for log files.**

## Directory Structure
```
logs/
├── AccessLogs/              # HTTP access logs (duration, bytes, status)
├── Codebeamber/             # Codebeamer access logs
└── ThingworxLogs/           # ThingWorx application logs
    └── CustomThingworxLogs/ # Custom ScriptLogs with durationMS
```

---

## AccessLogs/ - HTTP Request Logs (duration, bytes, status)

| File | Server | Latency Unit | Metrics | Size | Use Case |
|------|--------|--------------|---------|------|----------|
| `ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | Apache HTTP Server 2.x | microseconds (%D) | duration, bytes, count | 658KB | Apache HTTP2 with microsecond latency |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 277MB | Primary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 220MB | Secondary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 148MB | Smaller Tomcat 9 access log test |
| `localhost_access_log.2025-03-21.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes, count | 2.6MB | Small access log for quick tests |

**Format**: Apache combined log with duration at end (units vary by server)
```
# Apache HTTP Server 2.x - microseconds
127.0.0.1 - - [22/Jan/2026:08:49:51 +0000] "GET /path HTTP/1.1" 200 209 173542

# Tomcat 9 - milliseconds
10.224.34.60 - - [05/May/2025:00:00:00 +0000] "POST /path HTTP/1.1" 200 261 1
```
Fields: IP, -, -, [timestamp], "method path protocol", status_code, bytes, duration

**Note**: Apache HTTP Server uses `%D` for microseconds, while Tomcat uses `%D` for milliseconds. The ltl tool auto-detects the unit based on value ranges.

---

## Codebeamber/ - Codebeamer Access Logs

| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `codebeamer_access_log.2025-10-29.txt` | duration, bytes, count | 83KB | Codebeamer format testing |

**Format**: Apache-style with duration in brackets
```
127.0.0.1 - - [29/Oct/2025:08:03:31 +0000] "GET /hc/ping.spr HTTP/1.1" 200 112 [293ms] [0.293s]
```

---

## ThingworxLogs/ - ThingWorx Application Logs

All ThingWorx logs use this standard format:
```
2025-05-05 00:00:00.006+0000 [L: ERROR] [O: c.p.a.u.JobPurgeScheduler] [I: ] [U: SuperUser] [S: ] [P: ] [T: ThreadName] Message
```
Fields: timestamp [L: level] [O: origin] [I: instance] [U: user] [S: session] [P: process] [T: thread] message

### ApplicationLog (General platform activity)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ApplicationLog.2025-05-05.0.log` | occurrences only | 85MB | Large Linux ApplicationLog |
| `ApplicationLog.2025-05-06.0.log` | occurrences only | 6.5MB | Medium ApplicationLog |
| `ApplicationLog.2025-12-12.282-Windows.log` | occurrences only | 10MB | Windows ApplicationLog |
| `ApplicationLog.log` | occurrences only | 5.8MB | Current ApplicationLog |
| `ApplicationLog-improperlyRead.log` | occurrences only | 468B | Edge case - malformed reads |

### ScriptLog (Script execution logs)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ScriptLog.2025-05-05.0.log` | occurrences only | 13MB | Standard ScriptLog |
| `ScriptLog.2025-05-06.0.log` | occurrences only | 15MB | Standard ScriptLog |
| `ScriptLog.2025-12-17.0.Rolex.log` | occurrences only | 1.6MB | Basic ScriptLog test |
| `ScriptLog.log` | occurrences only | 4.4MB | Current ScriptLog |

### ErrorLog (Error-level messages)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ErrorLog.2025-05-05.1.log` | occurrences only | 61MB | Large error log (auth failures, etc.) |
| `ErrorLog.2025-05-06.0.log` | occurrences only | 3.3MB | Medium error log |
| `ErrorLog.log` | occurrences only | 3.7MB | Current error log |

### SecurityLog (Security events)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `SecurityLog.2025-05-05.1.log` | occurrences only | 70MB | Large security log (nonce rejections) |
| `SecurityLog.2025-05-06.0.log` | occurrences only | 3.0MB | Medium security log |
| `SecurityLog.log` | occurrences only | 3.6MB | Current security log |

### ScriptErrorLog (Script-specific errors)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ScriptErrorLog.2025-05-05.0.log` | occurrences only | 14MB | Script error analysis |
| `ScriptErrorLog.2025-05-06.0.log` | occurrences only | 14MB | Script error analysis |
| `ScriptErrorLog.log` | occurrences only | 2.5MB | Current script errors |

### DatabaseLog (Database operations)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `DatabaseLog.2025-05-05.0.log` | occurrences only | 700KB | Database error tracking |
| `DatabaseLog.2025-05-06.0.log` | occurrences only | 693KB | Database error tracking |
| `DatabaseLog.log` | occurrences only | 29KB | Current database log |

### AuthLog (Authentication events)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `AuthLog.2025-05-05.0.log` | occurrences only | 324KB | SAML/SSO authentication events |
| `AuthLog.2025-05-06.0.log` | occurrences only | 257KB | Authentication events |
| `AuthLog.log` | occurrences only | 167KB | Current auth log |

### ConfigurationLog (Configuration changes)
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ConfigurationLog.2025-05-05.0.log` | occurrences only | 30KB | Configuration tracking |
| `ConfigurationLog.2025-05-06.0.log` | occurrences only | 31KB | Configuration tracking |
| `ConfigurationLog.log` | occurrences only | 31KB | Current configuration log |

### Other ThingWorx Logs
| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `CommunicationLog.2025-05-06.0.log` | occurrences only | 190B | Communication events (minimal) |
| `AkkaCommunicationLog.log` | occurrences only | 2.2KB | Akka communication events |

---

## ThingworxLogs/CustomThingworxLogs/ - ScriptLogs with Full Metrics

These logs contain `durationMS=`, `result bytes=`, and `result count=` fields enabling all metric types for analysis and heatmaps.

| File | Metrics | Size | Use Case |
|------|---------|------|----------|
| `ScriptLog-DPMExtended-clean.log` | duration, bytes, count | 29MB | Cleaned DPM ScriptLog - ideal for all heatmap types |
| `ScriptLog.2025-04-09.1.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.2.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.3.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-09.4.log` | duration, bytes, count | 72MB | Large ScriptLog with full metrics |
| `ScriptLog.2025-04-10.0.log` | duration, bytes, count | 98MB | Large ScriptLog with full metrics |
| `ScriptLog.GetComplexPlotByIndex.log` | duration, bytes, count | 739KB | Specific service analysis |
| `ScriptLog.log` | duration, bytes, count | 54MB | ScriptLog with full metrics |

**Format**: ThingWorx ScriptLog with embedded metrics
```
2025-04-10 04:46:35.844+0000 [L: WARN] ... durationMS=167 events to be processed count=0
2025-04-10 05:00:03.529+0000 [L: INFO] ... durationMS=1041 result count=12 result bytes=6059
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
./ltl -n 10 logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Error analysis
./ltl -n 20 logs/ThingworxLogs/ErrorLog.2025-05-05.1.log

# Security event analysis
./ltl -n 10 logs/ThingworxLogs/SecurityLog.2025-05-05.1.log

# Codebeamer access log
./ltl -hm duration logs/Codebeamber/codebeamer_access_log.2025-10-29.txt
```

## Logs by Use Case

| Use Case | Recommended Log Files |
|----------|----------------------|
| **Duration/latency heatmap** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Bytes/response size analysis** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Count/frequency analysis** | Any log file |
| **All three metrics (duration, bytes, count)** | `AccessLogs/*.txt`, `ThingworxLogs/CustomThingworxLogs/*` |
| **Error analysis** | `ThingworxLogs/ErrorLog.*`, `ThingworxLogs/ScriptErrorLog.*` |
| **Security events** | `ThingworxLogs/SecurityLog.*`, `ThingworxLogs/AuthLog.*` |
| **Database issues** | `ThingworxLogs/DatabaseLog.*` |
| **Quick tests (small files)** | `AccessLogs/localhost_access_log.2025-03-21.txt`, `Codebeamber/*`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log` |
| **Large file stress tests** | `AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`, `ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.*.log` |
