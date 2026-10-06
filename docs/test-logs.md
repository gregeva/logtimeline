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
├── Sets/                   # Environment sets: every log family of one environment over one period (§ Sets)
├── IntegrationRuntimeLogs/  # ThingWorx Integration Runtime logs (yyyy-dd-MM dates)
└── ThingworxLogs/           # ThingWorx application logs
    ├── CXS/                 # ThingWorx Connection Server logs
    └── CustomThingworxLogs/ # Custom ScriptLogs with durationMS
```

---

## Sets/ - Environment Sets (every log family of one environment over one time frame)

A set is everything one PLM application environment wrote over one period, kept together so that the families can be read against each other: the Apache access log, the `mod_jk` connector log, the Method Server, Background Method Server and ServerManager `log4j` logs, and each JVM's G1 GC log. Every family in every set stamps UTC, so a restart or an outage shows at the same second in each of them. Each set has two nodes, `node1/` and `node2/`, each with the deployment's own layout: `apachelogs/` (access and connector logs, daily rotation `_YYYY-MM-DD_00_00_00`) and `logs/` (the `log4j` logs with their `.YYYY-MM-DD_N` rotations, and the `-GC.log` files, one per JVM start). File names are the deployment's own; host names appear only inside a few `log4j` records.

| Set | Environment | Period | Condition | Files | Size | Lines |
|---|---|---|---|---|---|---|
| `windchill-jdk17-two-node-fortnight/` | Windchill 13.0.2, OpenJDK 17.0.13, G1, 12 GB method-server heap, 8 GB background heap | 2026-08-19 to 2026-08-31 (GC logs from 2026-08-16) | Steady fortnight: daily connector marshalling failures (the 413s), one maintenance restart window on 2026-08-30 from 01:18 to 02:07 UTC on both nodes (`All tomcat instances failed`, connect failures, then recovery), and 36 `To-space exhausted` evacuation failures on the background servers, two to four a day from 2026-08-17 to 2026-08-29. GC logs limited to five JVMs: both method servers, two background servers, one ServerManager | 404 | 4.3GB | 26,060,315 |
| `windchill-jdk21-balancer-outage/` | Windchill 13.12, OpenJDK 21.0.11, G1, 5.9 GB method-server heap, 4.9 GB background heap | 2026-08-19 to 2026-08-31 (GC logs from 2026-08-09) | Balancer outage on 2026-08-21: node 1's method server restarted at 11:45:40 UTC and node 2's at 11:50:58; the connector wrote 8 lines on node 1 (11:45:33 to 11:45:40) and 2,377 on node 2 (11:50:50 to 11:52:01), `All tomcat instances failed, no more workers left` on nearly every one; the GC logs of both method servers end and begin at those seconds. A second 59-line burst on node 2 on 2026-08-29 at 08:56:57. The JDK 21 GC logs carry `Evacuation Failure` on the pause line (1,047 on node 1's method server) | 231 | 1.4GB | 9,789,647 |
| `windchill-heap-pressure-restart/` | Windchill 12.12, JVM version not written in the GC log, G1, 5.9 GB method-server heap, 4.9 GB background heap | 2026-08-19 to 2026-08-31 (access logs 2026-08-19 to 2026-08-23 only; GC logs from 2026-07-18) | Heap pressure and a planned restart: every JVM's GC log carries thousands of `Pause Full` collections before the restart on 2026-08-23 between 01:05 and 01:13 UTC (the connector's 83 lines are that window), and continues after it with full collections still frequent. The smallest set; every family of a two-node environment at manageable size | 142 | 213MB | 1,981,965 |

Per family, both nodes together:

| Set | access | mod_jk | MethodServer | Background servers | ServerManager | GC |
|---|---|---|---|---|---|---|
| `windchill-jdk17-two-node-fortnight/` | 26 files, 2.2GB, 8,266,583 | 23 files, 1,254 lines | 252 files, 1.9GB, 16,291,556 | 66 files, 79MB, 374,948 | 32 files, 3.0MB, 14,694 | 5 files, 82MB, 1,111,280 |
| `windchill-jdk21-balancer-outage/` | 26 files, 297MB, 1,008,114 | 3 files, 2,444 lines | 125 files, 887MB, 6,965,816 | 41 files, 97MB, 631,359 | 26 files, 25MB, 178,694 | 10 files, 73MB, 1,003,220 |
| `windchill-heap-pressure-restart/` | 10 files, 43MB, 265,040 | 2 files, 83 lines | 42 files, 44MB, 268,980 | 42 files, 14MB, 35,607 | 28 files, 3.3MB, 14,217 | 18 files, 108MB, 1,398,038 |

Formats: access logs bind `access_common_duration` (microsecond `%D`, read with `-du us`); connector logs bind `apache_mod_jk`; Method Server and background-server logs bind `windchill_method_server`; GC logs bind `java_gc_g1_time` (the time-only decoration, no level or tags); ServerManager logs bind no format (#675). Background-server file stems are `BackgroundMethodServer`, `BGMSINDX` (indexing) and `BGMSWVS` (visualisation). Each family's files are also listed in that family's section below.

### What each set shows, and the command that shows it

Each row is a condition observed in the set, the files that carry it and a command, run from the set's folder, that puts it on the timeline. These are the scenarios for exercising existing capabilities and for finding the ones that are missing; every command below was run and shows what the row says.

**`windchill-jdk17-two-node-fortnight/`**

| Condition | Files | Command | What appears |
|---|---|---|---|
| Connector marshalling failures are the access log's 413s, hour for hour | `node1/apachelogs/mod_jk.log_2026-08-25_00_00_00`, `node1/apachelogs/access.log_2026-08-25_00_00_00` | `ltl -bs 60 -oe node1/apachelogs/mod_jk.log_2026-08-25_00_00_00` then `ltl -bs 60 -oe -i '" 413 ' node1/apachelogs/access.log_2026-08-25_00_00_00` | 102 connector errors and 102 requests with status 413, the same count in every hour (8, 14, 20, 25, 14, 8, 4, 2, 6 from 14:00 to 22:00). The two files on one timeline is the reading the connector format exists for |
| Maintenance restart window: failures, then recovery, with held requests released | `node1/apachelogs/access.log_2026-08-30_00_00_00`, `node1/apachelogs/mod_jk.log_2026-08-30_00_00_00` | `ltl -bs 5 -st 01:00 -et 02:30 -oe -hf node1/apachelogs/access.log_2026-08-30_00_00_00 node1/apachelogs/mod_jk.log_2026-08-30_00_00_00` | Failures from 01:15 to 01:25 and again at 02:00 to 02:05 while the 2xx count halves; P95 duration in hours in the failing buckets, minutes outside them |
| JDK 17 evacuation failure written as its own line | `node2/logs/BGMSWVS-260816022753624-2-GC.log` | `ltl -bs 1440 -i "To-space" node2/logs/BGMSWVS-260816022753624-2-GC.log` | 32 `To-space exhausted` records over the fortnight, two to four a day; the `Pause Young` that each one belongs to is the previous record |
| Pause distribution and heap heatmap of a method server's fortnight | `node1/logs/MethodServer-260816022715264-1-GC.log` | `ltl -bs 60 -hg -hm bytes node1/logs/MethodServer-260816022715264-1-GC.log` | 22,951 pauses, P50 28 ms, P99 191 ms, P99.9 325 ms; the heap-delta heatmap climbs to 9.8 GiB on a 12 GiB heap |
| A family no format reads (#675) | `node1/logs/ServerManager-2608160227-4140140-log4j.log` | `ltl node1/logs/ServerManager-2608160227-4140140-log4j.log` | `Read 46 lines, however no lines matched any of the patterns` |

**`windchill-jdk21-balancer-outage/`**

| Condition | Files | Command | What appears |
|---|---|---|---|
| The outage minute, from the connector | `node2/apachelogs/mod_jk.log_2026-08-21_00_00_00` | `ltl -bs 1 -st 11:40 -et 12:00 -oe node2/apachelogs/mod_jk.log_2026-08-21_00_00_00` | 110 errors at 11:50, 2,300 at 11:51, 9 at 11:52, nothing before or after; every line failure-classified |
| What the users saw, and the surge that preceded it | `node2/apachelogs/access.log_2026-08-21_00_00_00` | `ltl -bs 1 -st 11:40 -et 12:00 -oe -hf node2/apachelogs/access.log_2026-08-21_00_00_00` | Eight requests a minute until 11:47, then 146, 1,200 and 1,000 a minute from 11:48 (a burst of 1,694 signed direct-download requests, P50 12 s), 9.5% failures at 11:50 and 99.9% at 11:51 (2,300 of 2,302), back to 100% success at 11:52 |
| Both families on one clock | the two files above | `ltl -bs 1 -st 11:40 -et 12:00 -oe -hf node2/apachelogs/access.log_2026-08-21_00_00_00 node2/apachelogs/mod_jk.log_2026-08-21_00_00_00` | A two-format legend; the 11:51 bucket carries 2,300 access failures and 2,300 connector errors side by side, P50 duration 1.7 min against 1.4 s before the surge |
| The method server's JVM through the outage: pause storm, full GC, restart | `node2/logs/MethodServer-260809041626499-3-GC.log` (ends 11:50:58), `node2/logs/MethodServer-260821115058428-4-GC.log` (begins 11:50:58) | `ltl -bs 1 -st "2026-08-21 11:40" -et "2026-08-21 12:00" -oe node2/logs/MethodServer-260809041626499-3-GC.log node2/logs/MethodServer-260821115058428-4-GC.log` | From one pause a minute to 20, 34 and 29 at 11:49 to 11:51, a `Pause Full` and a `Using G1` (the new JVM) both at 11:50, settling by 11:54 |
| JDK 21 evacuation failure on the pause line | `node1/logs/MethodServer-260809041601031-1-GC.log` | `ltl -bs 1440 -i "Evacuation Failure" node1/logs/MethodServer-260809041601031-1-GC.log` | 1,047 `Pause Young` records carrying the suffix, by day; the JDK 17 set writes the same condition as a separate line |

**`windchill-heap-pressure-restart/`**

| Condition | Files | Command | What appears |
|---|---|---|---|
| A full collection every ten minutes, around the clock | `node1/logs/MethodServer-260718174708212-1-GC.log.0` | `ltl -bs 60 -oe -i "Pause Full" node1/logs/MethodServer-260718174708212-1-GC.log.0` | 6 `Pause Full` an hour from the first hour to the last, 9,664 in the file, every one caused by `System.gc()`: an explicit collection on a timer, not heap exhaustion |
| The planned restart as the web tier saw it | `node1/apachelogs/access.log_2026-08-23_00_00_00`, `node1/apachelogs/mod_jk.log_2026-08-23_00_00_00` | `ltl -bs 1 -st 01:00 -et 01:20 -oe -hf node1/apachelogs/access.log_2026-08-23_00_00_00 node1/apachelogs/mod_jk.log_2026-08-23_00_00_00` | Failures at 01:05 and 01:06, nothing from 01:07 to 01:10, failures again at 01:11 and 01:12 as the new servers come up, then a bucket whose P50 duration is 8.7 hours: requests held across the restart and released at 01:13 |
| The same restart from inside the method server | `node1/logs/MethodServer-2607181747-362981-log4j.log` (before), `node1/logs/MethodServer-2608230111-3901060-log4j.log.2026-08-23_1` (after) | `ltl -bs 1 -st 01:00 -et 01:20 -oe node1/logs/MethodServer-2607181747-362981-log4j.log node1/logs/MethodServer-2608230111-3901060-log4j.log.2026-08-23_1` | 3 FATAL, 17 ERROR and 716 INFO records in the shutdown minute 01:05, silence to 01:10, the startup's 161 INFO records at 01:11, ten errors at 01:12 |

---


## AccessLogs/ - HTTP Request Logs (duration, bytes, status)

| File | Server | Latency Unit | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|---|---|
| `ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | Apache HTTP Server 2.x | microseconds (%D) | duration, bytes | 98KB | 677 | Apache HTTP2 with microsecond latency (the `-FULL` sibling is 658KB) |
| `access.log_2026-05-19_00_00_00` | Apache HTTP Server 2.x (Windchill) | microseconds (%D), read with `-du us` | duration, bytes | 41MB | 84,876 | One full day of Windchill traffic; binds `access_common_duration` on every line, no thread or session field. 76,142 lines carry a query string, 74,305 of them signed direct-download requests (`doDirectDownload`) with fifteen parameters each: the file's identity (`fileName`, `adId`: 22,431 distinct) beside per-request values (`sign` unique on every line, `sT` signing time, `refsize`) and constants (`userid`, `AUTH_CODE`, `site`). The query-string specimen for keeping or discarding named parameters and for consolidation under `-xqs`. 2,130 lines carry a populated remote user |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 277MB | 1,430,678 | Primary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-06.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 220MB | 1,133,132 | Secondary Tomcat 9 access log test |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 148MB | 761,698 | Smaller Tomcat 9 access log test |
| `localhost_access_log.2025-03-21.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 2.6MB | 22,264 | **CORRUPT — do not use for clean-output testing.** Contains concatenated records (two log lines merged on one line), so field captures pick up fragments of the following record (e.g. an IP fragment where the duration belongs). Useful only as adversarial malformed input; ltl treats such non-numeric duration captures as unobserved (#341, #345). No harness uses this file (the regression/ticks fixture is derived from the 2025-05-07 corpus via `tests/lib/fixtures.sh`) |
| `localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt` | Tomcat 9 | milliseconds (%D) | duration, bytes | 1.0MB | 5,000 | 5k-line slice from 05-05 log; the configuration-class fixture for `tests/validate-index-read-back.sh`, `validate-histogram-bin-counters.sh`, `validate-format-detection.sh`, `validate-statistics-demand.sh`, `validate-numeric-criteria-notices.sh`. Regenerate via `tests/fixtures/regenerate-index-readback-fixtures.sh` |
| `tests/fixtures/tomcat-access-duration-spread.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 52KB | 434 | Deterministic synthetic fixture for `tests/validate-duration-display.sh`: 12 generic endpoints over a 14.5 h span with duration values chosen to render every cell class (0ms, 1ms, 58ms, 166ms, 1s, 1.4s, 5.5s). TEST-NET addresses, no real hosts or paths. Regenerate via `tests/duration-display/generate-fixture.py` |
| `tests/fixtures/tomcat-access-single-sample-keys.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 12 | The first 12 lines of `tomcat-access-duration-spread.txt`: twelve distinct endpoints, one request each, so every message key carries exactly one duration and none reaches the n ≥ 2 (`cv`, `stddev`) or n ≥ 4 (shape) sort-eligibility floors. Exercises the post-walk unsatisfiable-sort fallback in `tests/validate-statistics-demand.sh` |
| `tests/fixtures/gated-means-access.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 8 | Eight requests over six minutes, one path per case: sizes 512 and 513 in one minute (one mean, two roundings), a minute whose only line has `-` for its size (bytes unobserved), a minute whose only line is a zero-byte response (an observed zero), durations 100 then 0 a minute apart (a minute holding only a zero duration; impact's order dependence), and durations 1 and 0 in one minute (a mean of 0.5). At `-bs 1` each case is its own bucket. The fixture for the unobserved-metric scenarios of `tests/validate-csv-output.sh`, `tests/validate-duration-display.sh` and `tests/validate-aggregate-export.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/http-status-families.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 10 | Two lines per HTTP status family (1xx–5xx) over ten consecutive seconds, three of them on a `/store/orders` path so a highlight produces a highlighted twin for 2xx, 4xx and 5xx. The category-name fixture for `tests/validate-category-names.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/category-contribution-skew.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 4KB | 53 | Four HTTP status families in deliberately unequal proportions — 40 / 8 / 4 / 1 lines — over one minute, so the contribution bars drawn across the category rows have four distinct lengths at every scale and a bar measured against the wrong reference cannot land on the right length by chance. The single 5xx line is the tail case the logarithmic scale exists for. The fixture for `tests/validate-summary-contribution-bar.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/profile-weekend-fold.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 5 | One line per day, Wednesday to Sunday, at the same time of day, so a `-pr workday` fold drops exactly the two weekend lines. The profile-fold fixture for `tests/validate-filter-summary.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/bucket-size-units.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 4 | One line per day, four days, carrying one duration per display-ladder step above a day (10 days, 45 days, 400 days) and one value of 500 that reads as 500 ns under `-du ns`. The display-ladder fixture for `tests/validate-bucket-size-units.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/access-bracketed-sub-millisecond.txt` | access log with bracketed durations (synthetic) | microseconds, written per line (`[150us]`); the format declares milliseconds | duration, bytes | 1KB | 6 | Six requests one second apart whose durations sit either side of 0.2 ms (150, 199, 200, 201, 250 and 1500 microseconds), so a sub-millisecond duration bound (`-dmin 200us`, `-dmin 0.2`) keeps exactly four lines; the fixture for the sub-millisecond scenario of `tests/validate-option-resolution.sh` |
| `tests/fixtures/byte-boundary.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 9 | Nine lines, one per minute, whose response sizes sit either side of each byte-unit step: 999, 1000, 1023, 1024, 999999, 1000000, 1048575, 1048576 and 1500000. At `-bs 1` each line is its own bucket, so the STATS `bytes_nice` cells show the formatter's answer for each size. The fixture for `tests/validate-byte-units.sh` and the `byte-notation` scenario of `tests/validate-format-detection.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/udm-byte-units.txt` | Tomcat 9 (synthetic) | milliseconds (%D) | duration, bytes | 1KB | 3 | Three lines in one minute whose query strings carry `v=1`, `v=2` and `v=3`, so a byte-unit metric `-udm v:<unit>:max` reads 3 × the unit's byte count. The byte-unit-slot fixture for `tests/validate-udm-specs.sh`. TEST-NET addresses, no real hosts or paths |
| `tests/fixtures/classification-states.txt` | classification verification format (synthetic, pin with `-lf classification_verification`) | milliseconds | duration | 2KB | 16 | Sixteen lines over four days carrying every classification state: all-success, all-failure, all-conflict and all-unclassified rows, a success/failure row and a success/unclassified row (both mixed), a near-identical pair that consolidates under `-g`, and one day each where only a conflict or only a qualifying-source unclassified line withholds the bucket's percentages. Unrecognised by detection; the producer for `tests/validate-classification-states.sh`. No real hosts or paths |
| `tests/fixtures/grouping-signed-downloads.txt` | Apache HTTP Server 2.x (scrubbed sample) | microseconds (%D), read with `-du us` | duration, bytes | 204KB | 400 | A contiguous run of signed direct-download requests from a PLM application's access log, fifteen query parameters each: file identity (folder, file id, file name) beside per-request values (signature unique on every line, signing time, response size, counter). Under `-xqs` every message key has a partner at Dice 75 to 79 and no pair reaches Dice 85, while the rarest trigrams of each key come from its per-request values. The candidate-search fixture for `tests/validate-message-grouping.sh`. Client address TEST-NET; user id, authentication scheme and site replaced by neutral constants; identifiers replaced consistently preserving length, character class and shared leading digits; signatures re-randomised. Regenerate via `tests/fixtures/regenerate-grouping-signed-downloads.sh` |
| `localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` | Tomcat 9 | milliseconds (%D, fractional, three places) | duration, bytes, thread, session | 118MB | 517,684 | The common-plus-duration-thread-session shape (`access_common_duration_thread_session`): a fractional millisecond duration, the thread name on every line, a session id on a third to four fifths of the lines and `-` elsewhere. Thread-session shape specimen; no line carries `null` as its thread |
| `access.log-20260609` | nginx (custom `log_format`) | none read | bytes | 37MB | 219,933 | Combined format plus a quoted forwarded-for and six `key="value"` pairs (a decimal-seconds request time among them). Binds `access_combined`; no duration is read from a custom nginx format. Two lines carry a populated remote user |
| `really-big/*` | Tomcat 9 (thirty days) | milliseconds (%D); fractional on the later shape | duration, bytes; thread and session on the later shape | 8.5GB | — | Really big access logs from five servers over 30 days (`-0` to `-4`, thirty files each). The shape changes on one date on every server: the common-plus-duration shape (`access_common_duration`, integer milliseconds, 90 files) becomes the thread-session shape (`access_common_duration_thread_session`, fractional milliseconds, 60 files). 3,290 thread-session lines across 31 files carry the literal `null` as their thread (from 1 to 558 per file) |
| `Sets/windchill-jdk17-two-node-fortnight/node*/apachelogs/access.log_*` | Apache HTTP Server 2.x (Windchill) | microseconds (%D), read with `-du us` | duration, bytes | 2.2GB | 8,266,583 | Thirteen daily rotations per node, 2026-08-19 to 2026-08-31, the busiest of the three sets (up to 134MB a day). The 413s match the connector's marshalling failures to the second; the 503s of 2026-08-30 01:18 to 02:07 match its restart window. See § Sets |
| `Sets/windchill-jdk21-balancer-outage/node*/apachelogs/access.log_*` | Apache HTTP Server 2.x (Windchill) | microseconds (%D), read with `-du us` | duration, bytes | 297MB | 1,008,114 | Thirteen daily rotations per node, 2026-08-19 to 2026-08-31; the 2026-08-21 files carry the balancer outage of 11:45 to 11:52. See § Sets |
| `Sets/windchill-heap-pressure-restart/node*/apachelogs/access.log_*` | Apache HTTP Server 2.x (Windchill) | microseconds (%D), read with `-du us` | duration, bytes | 43MB | 265,040 | Five daily rotations per node, 2026-08-19 to 2026-08-23, ending in the planned restart of 2026-08-23 01:05 to 01:13. See § Sets |

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
| `Sets/windchill-jdk17-two-node-fortnight/node*/logs/` | Two nodes, thirteen days, one method server and three background services per node (`BackgroundMethodServer`, `BGMSINDX`, `BGMSWVS`) | 318 (252 MethodServer, 66 background) | 2.0GB | 16,666,504 | The largest method-server set, 9 to 14 rotations a day per node on weekdays. The ServerManager logs beside them bind no format (#675). See § Sets |
| `Sets/windchill-jdk21-balancer-outage/node*/logs/` | Two nodes, thirteen days; node 1's method server from 2026-08-18 | 166 (125 MethodServer, 41 background) | 984MB | 7,597,175 | The 2026-08-21 rotations hold both method-server restarts (11:45:40 and 11:50:58). See § Sets |
| `Sets/windchill-heap-pressure-restart/node*/logs/` | Two nodes, thirteen days, a planned restart on 2026-08-23 at 01:05 to 01:13 splitting every service's rotation sequence | 84 (42 MethodServer, 42 background) | 58MB | 304,587 | Smallest complete two-node set; every day's rotation is a single file of about 1MB. See § Sets |

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

The `GC/logs-gc/` files carry the time, level and tags decoration (`java_gc_g1`); the environment sets under `Sets/` carry the time-only decoration (`java_gc_g1_time`), JDK 17 and JDK 21, listed below and in § Sets.

| File | Metrics | Size | Lines | Use Case |
|---|---|---|---|---|
| `gc-twx01-twx-thingworx-2.out.8` | duration (pause), heap delta | 79MB | 781,118 | Largest GC log; best single file for scale testing |
| `gc-twx01-twx-thingworx-3.out.6` | duration (pause), heap delta | 62MB | 599,346 | Second-largest GC log |
| `gc-twx01-twx-thingworx-0.out.6` | duration (pause), heap delta | 50MB | 495,015 | Third-largest GC log |
| (many smaller rotations) | duration (pause), heap delta | 1.4KB–33MB | — | Rotated GC logs from 5 servers |
| `Sets/windchill-jdk17-two-node-fortnight/node*/logs/*-GC.log` | duration (pause), heap delta | 82MB | 1,111,280 | Five JDK 17 logs, 2026-08-16 to 2026-08-30, time-only decoration (`java_gc_g1_time`): both method servers (about 23,000 pauses each), two background servers carrying `To-space exhausted` as a separate line (4 and 32 times), one 288-line ServerManager log for quick iteration |
| `Sets/windchill-jdk21-balancer-outage/node*/logs/*-GC.log` | duration (pause), heap delta | 73MB | 1,003,220 | Ten JDK 21 logs, 2026-08-09 to 2026-08-31, time-only decoration; `Evacuation Failure` written on the pause line (1,047 on node 1's method server); the method-server logs break at the 2026-08-21 restarts |
| `Sets/windchill-heap-pressure-restart/node*/logs/*-GC.log*` | duration (pause), heap delta | 108MB | 1,398,038 | Eighteen logs, 2026-07-18 to 2026-08-31, time-only decoration, JVM version not written; the JVMs before the 2026-08-23 restart carry thousands of `Pause Full` each (up to 11,828), including `.log.0` and `.log.1` size rotations; `Pause Full` continues after the restart |

**Format**: JVM unified logging
```
[2025-04-05T11:10:47.867+0000][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 2433M->66M(49152M) 18.406ms
```

---

## Sets/*/node*/apachelogs/mod_jk.log_* - Apache mod_jk Connector Logs

The connector's error log on each Apache node, daily rotation named like the access log beside it. One line shape across every file (millisecond stamp, request-id placeholder, `apache_mod_jk`), every line at `error` level. The errors correlate with the access log to the second: each `failed appending ...` marshalling error is one HTTP 413, `All tomcat instances failed, no more workers left` is a 503 window.

| Folder | Files | Lines | Use Case |
|---|---|---|---|
| `Sets/windchill-jdk17-two-node-fortnight/node*/apachelogs/` | 23 | 1,254 | Steady failures: 649 query-string, 116 remote-port, 92 activation-state and 86 local-address marshalling failures over thirteen days, 95 all-workers-failed lines in the 2026-08-30 restart window |
| `Sets/windchill-jdk21-balancer-outage/node*/apachelogs/` | 3 | 2,444 | The outage burst: 2,377 lines in 71 seconds on node 2 and 8 on node 1 on 2026-08-21, 2,411 of them all-workers-failed; a 59-line burst on node 2 on 2026-08-29 |
| `Sets/windchill-heap-pressure-restart/node*/apachelogs/` | 2 | 83 | The restart window alone: connect failures and all-workers-failed lines between 01:05 and 01:13 on 2026-08-23 |

**Format**: `apache_mod_jk`
```
[Sun Aug 30 01:18:06.969 2026] [NO-ID] [4140494:139979065804352] [error] ajp_send_request::jk_ajp_common.c (1777): (tomcat1) connecting to backend failed. Tomcat is probably not started or is listening on the wrong port (errno=111)
[Sun Aug 30 01:18:07.070 2026] [NO-ID] [4140494:139979065804352] [error] service::jk_lb_worker.c (1687): All tomcat instances failed, no more workers left
```
`[weekday month day HH:MM:SS.mmm year] [request id] [pid:tid] [level] function::source (line): (worker) message`; no time zone written, UTC on every set. The committed fixtures under `tests/fixtures/format-detection/apache-mod-jk*.txt` are scrubbed slices and synthetic variants of this family (see the manifest there).

---

## Sets/*/node*/logs/ServerManager-*-log4j.log* - Windchill ServerManager Logs

The ServerManager is the process that starts and monitors the method servers on a node; its `log4j` log sits beside theirs with the same file naming and daily rotation. **No format reads it** (#675, filed from these sets): every line is unmatched, with detection and with `-lf windchill_method_server`. The layout differs from the Method Server's in one place: `logger - message` with a single space, where the Method Server writes an empty NDC field and two spaces.

| Folder | Files | Lines | Use Case |
|---|---|---|---|
| `Sets/windchill-jdk17-two-node-fortnight/node*/logs/` | 32 | 14,694 | Smallest files of the family (45 lines on the smallest); the reproduction for #675 |
| `Sets/windchill-jdk21-balancer-outage/node*/logs/` | 26 | 178,694 | Densest ServerManager logs: RMI connection errors dominate |
| `Sets/windchill-heap-pressure-restart/node*/logs/` | 28 | 14,217 | Rotation sequence split by the 2026-08-23 restart |

Across the 86 files, 82% of records are ERROR (RMI connection handling), 9% WARN and 9% INFO: a `wt.summary.general` line every ten minutes with the JVM's heap and non-heap usage, and a liveness ping every five minutes. Stack-trace continuation lines follow the ERROR records.

```
2026-08-30 00:02:50,656 INFO  [WindchillAIAssistantPinger] wt.server.manager.startup - WindchillAIAssistant at port 8100 is alive.
2026-08-30 00:07:18,134 INFO  [wt.jmx.core.SharedScheduledExecutor.worker] wt.summary.general - JVMName=4140140@node1.example.internal, HeapMemoryUsage=2982303968, NonHeapMemoryUsage=122...
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
| `tests/fixtures/gated-means-application.txt` | duration, bytes | 1KB | 9 | Synthetic ScriptLog lines over five minutes: a minute whose only line carries a duration and no bytes, one whose only line carries bytes and no duration, four `Processing request <uuid> done` lines of which two carry a duration (the consolidation case under `-g 50`), a message of two lines carrying no metric, and a minute whose only line carries a zero duration. At `-bs 1` each case is its own bucket. The fixture for the unobserved-metric scenarios of `tests/validate-csv-output.sh`, `tests/validate-duration-display.sh` and `tests/validate-aggregate-export.sh` |
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
| **Cross-family correlation (access, connector, method server, GC on one clock)** | `Sets/*` (§ Sets); the outage: `Sets/windchill-jdk21-balancer-outage/node2/*/*2026-08-21*` |
| **Time-only G1 decoration (`java_gc_g1_time`), JDK 17 and 21** | `Sets/*/node*/logs/*-GC.log*` |
| **Connector errors beside access statuses** | `Sets/*/node*/apachelogs/mod_jk.log_*` with the same day's `access.log_*` |
| **Unrecognised family (#675)** | `Sets/*/node*/logs/ServerManager-*-log4j.log*` |
