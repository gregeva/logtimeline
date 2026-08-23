# Feature: Windchill Method Server log4j format (Issue #396)

## Status

Implemented on `396-windchill-method-server-log4j-format`, targeting release 0.17.0.
Registry entry `mt17`, user-facing format name `windchill_method_server`, match_type 17.
Built on the Drop 1.5 mechanisms (filename evidence, `features/log-format-registry.md` D45/I4).

## Overview

Windchill's Method Server and Background Method Server processes write one
log4j pattern layout:

```
%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%t] %c %x - %m%n
```

The same layout is written by every service of the family — `MethodServer`,
`BackgroundMethodServer`, `BackgroundMethodServerCAD`,
`BackgroundMethodServerESI` — and the service is visible only in the file
name and in a few startup lines. Before this drop no registry entry recognised
the layout; every line of these files was unmatched.

## Format contract

### Line shape

```
2025-07-18 04:46:41,354 INFO  [main] wt.method.server.startup  - Starting BackgroundMethodServer
2025-07-18 06:28:01,115 ERROR [ajp-nio-127.0.0.1-8010-exec-2312] com.ptc.windchill.uwgm.proesrv.rrc.RequestResultCache user01 - UwgmObjectFactory.createPartIteration :: Unsupported PartType: RAW_MATERIAL
2025-07-18 04:52:55,260 WARN  [JMX Monitor ThreadGroup<main> Executor Pool [Thread-21]] wt.jmx.notif.methodContextGauge  - Time=2025-07-18 04:52:55.257 +0000, Name=MethodContextsGaugeNotifier
```

| Capture | Record field | Notes |
|---|---|---|
| `YYYY-MM-DD HH:MM:SS,mmm` | `timestamp_str` (+ `fractional_ms`) | comma fraction; `frac fixed3` strips it by offset, so no transform is needed |
| `%-5p` level | `category_bucket` | `INFO`, `ERROR`, `WARN`, `FATAL`, `TRACE`, … padded to five characters, hence one or two spaces before `[` |
| `[%t]` thread | `thread` | may nest brackets (`[… Pool [Thread-21]]`); captured lazily up to the first `] ` that the logger/NDC/separator tail follows |
| `%c` logger | `object` | dotted Java category — the same mapping the Connection Server entry uses |
| `%x` NDC | `user` | the user context; **the slot is always present** and is the empty string when no context is set, which is why user-less lines show two spaces before ` - ` |
| `%m` | `message` | free text; may be empty (the ` - ` separator is still written) |

Time contract: `iso_ms`, millisecond precision, **local server time, no
offset in the line** (`tz => 'local'`). No line-level duration, bytes or
count field exists; the entry is occurrences-only (`duration_unit undef`,
`stats_eligible 0`), like the other platform logs.

### Continuation lines

Multi-line records continue on lines with no timestamp: tab-indented
`\tat …` frames, unindented `Nested exception is:` / `Caused by:` /
`\t... N more`, property dumps (`StartTime=…,`, `--add-exports=…`),
space-indented version tables, and blank lines. None of these match any
registry entry; they are counted as unmatched lines, exactly as for the
ThingWorx `ScriptErrorLog` and the Connection Server payloads. Tab- and
space-led lines are rejected by the scan's whitespace dispatch before any
pattern runs; the rest fail at the timestamp anchor. No mechanism was added.

### Filename evidence

Producer-true name: `<Service>-<yyMMddHHmm>-<pid>-log4j.log`, where
`<Service>` is one of the four family members, `<yyMMddHHmm>` is the
process start time and `<pid>` its process id. Daily rotation appends
`.YYYY-MM-DD_N` **after** the extension
(`MethodServer-2507260852-2021933-log4j.log.2025-08-05_1`).

Declared as: `stem '(?:Background)?MethodServer(?:CAD|ESI)?-\d{10}-\d+-log4j'`,
`ext '.log'`, `placement 'after'`, `index 'date_n'` (no separate `date`
component — see D55). Six filename samples (one per service member, two
rolled forms) are the matcher's executable self-test at load.

## Locked decisions

### D54 — One entry with an OR-set stem, not a variant group (LOCKED 2026-08-23)

The four services write byte-identical lines with identical semantics: the
same time layout, the same local-time contract, no unit to differ on. A
variant group exists for producers whose *semantics* differ behind one
shape (Connection Server vs Integration Runtime date layout; Tomcat vs
httpd `%D` unit — `features/log-format-registry.md` D47), where choosing
the wrong member corrupts the output. Here every member would extract the
same record, so there is nothing to select and nothing a wrong choice could
corrupt.

Modelling them as four members was rejected on three concrete grounds:

- A group's default-selected member fires the ambiguity note (I6) whenever
  no evidence decides — every renamed or piped method-server file would get
  a note about a difference that does not exist.
- Four entries with one pattern would need four sample sets, four
  `expect` tables and four slots in `match_counts:` to prove the same
  extraction four times.
- The precedent is the ThingWorx family: `ApplicationLog`, `ErrorLog`,
  `ScriptErrorLog`, … share one entry (`mt1std`) with an OR-set stem,
  because they are one line format written to several files.

What is given up: the console legend names the *format*
(`windchill_method_server`), not the service. The service is already in the
file name, which the summary prints next to the bracket, so the analyst
loses nothing observable. Should a service ever diverge in semantics (a
different date layout, say), it becomes a group member at that point.

### D55 — The log4j daily-roll suffix is an index form that carries the date (LOCKED 2026-08-23)

The D45 resolver composes `stem ext[-date][.index]` for `placement after`;
the rotation here is `.YYYY-MM-DD_N` — a dot-separated composite of a date
and a counter that fits neither the `-date` nor the `.index` slot. Three
options were weighed:

1. Declare no rotation form — rolled files (48 of the 70 specimens) would
   match no stem and report no filename evidence at all.
2. Loosen the resolver's separators (`[-.]` before the date, `[._]` before
   the index) — changes every existing matcher's tolerance for one producer.
3. Add one index form to the vocabulary (I4 declares it extensible):
   `date_n => '(?<date>\d{4}-\d{2}-\d{2})_\d+'`.

Option 3 is taken. The form is consumed as an index (present/absent credit,
0.25 — F8) and, because the roll date *is* the content date (verified on all
48 rolled specimens: `…2025-08-05_1` starts at `2025-08-05 00:00:00,002`),
its named `date` capture feeds the D52 filename-date cross-check unchanged,
so `-V` reports `date=match` for a rolled file. An entry declaring `date_n`
may not also declare a `date` component; `compile_format_filename_matcher()`
rejects the combination at build.

### D56 — Thread capture is the lazy form, measured (LOCKED 2026-08-23)

Thread names nest brackets, so the plain `[^\]]*` capture drops those lines
(it cannot pass the inner `]`). Two correct forms were measured over 40,000
specimen lines (20k production MethodServer + 20k ESI; `Benchmark` `cmpthese`,
3 s per arm):

| Capture | Rate | per matched line |
|---|---|---|
| `((?:\](?! )\|[^\]])*)` — the ThingWorx idiom | 32.6/s | 0.77 µs |
| `(.*?)\] ` — lazy to the first `] ` the tail follows | 61.1/s | 0.41 µs |

Both match the same 18,627 records; the lazy form is 1.9× cheaper. On the
2.5M-line production set that is ≈0.9 s. The lazy form is shipped. Its
backtracking is bounded: a non-matching timestamped line walks the line
once, and such lines are rare (0 in the specimens, see below).

## Verification against the sample sets (2026-08-23)

Structural pass over the full local specimen set (70 files, 2,554,329
lines; a Perl classifier applying the entry's pattern, not `ltl`):

| Set | Service | Files | Lines | Records | Record share | Non-empty user | Levels |
|---|---|---|---|---|---|---|---|
| QA tiers | MethodServer | 12 | 14,852 | 9,924 | 66.8% | 48.4% | ERROR 4,654 · INFO 5,195 · WARN 63 · FATAL 12 |
| QA tiers | BackgroundMethodServer | 4 | 2,557 | 1,869 | 73.1% | 27.2% | INFO 1,383 · WARN 464 · ERROR 20 · FATAL 2 |
| QA tiers | BackgroundMethodServerCAD | 1 | 504 | 333 | 66.1% | 0.6% | INFO 295 · WARN 33 · ERROR 5 |
| QA tiers | BackgroundMethodServerESI | 1 | 65,088 | 1,356 | 2.1% | 100% | ERROR 1,356 (59,664 tab-indented frames) |
| Prod, 2 days | MethodServer | 45 | 2,157,463 | 1,634,743 | 75.8% | 96.4% | ERROR 1,589,344 · INFO 44,507 · WARN 882 · TRACE 10 |
| Prod, 2 days | BackgroundMethodServer | 3 | 203,479 | 203,071 | 99.8% | 98.9% | INFO 202,858 · WARN 171 · ERROR 42 |
| Prod, 1 day | MethodServer | 4 | 110,386 | 97,185 | 88.0% | 98.2% | ERROR 94,436 · INFO 2,668 · WARN 81 |

**Every timestamped line in the corpus matches the pattern** (0
timestamp-led lines rejected in all seven groups); every non-matching line
is a continuation line. The nested-bracket thread form and the empty-NDC
form both occur in the data (the issue described the user token as
"optional"; it is an always-present slot that is empty on 4% of production
lines and on most startup lines).

`ltl --disable-progress -ni -bs 1440 -oe -V format-detection` on 20,000-line
head excerpts (whole file where shorter), one per service member plus a
rolled production file:

| Excerpt | Lines | matched | unmatched | filename_evidence |
|---|---|---|---|---|
| `MethodServer-…-log4j.log` (QA) | 2,801 | 1,896 | 905 | `stem=mt17 ext=match date=- index=-` |
| `BackgroundMethodServer-…-log4j.log` (QA) | 779 | 607 | 172 | same |
| `BackgroundMethodServerCAD-…-log4j.log` | 504 | 333 | 171 | same |
| `BackgroundMethodServerESI-…-log4j.log` | 20,000 | 417 | 19,583 | same |
| `MethodServer-…-log4j.log` (prod) | 20,000 | 18,210 | 1,790 | same |
| `BackgroundMethodServer-…-log4j.log.2025-08-04_6` | 20,000 | 19,875 | 125 | `stem=mt17 ext=match date=match index=present` |

matched + unmatched = lines in every run; matched equals the classifier's
record count for the same excerpt; no ` at ltl line N` warning on stderr;
the D24 load-time gates (three samples with expected records, six filename
samples, cross-shadow, whitespace dispatch) pass on every start.

Cross-shadow: no existing pattern matches a method-server line (the comma
fraction and the level-before-thread order defeat the ThingWorx, RAC,
Connection Server and Analytics-worker heads), and the new pattern matches
none of the other entries' samples — `expect_ancestors => []` and the
derived constraints agree.

## Harness

`tests/validate-format-detection.sh` — four scenarios (22 assertions):

- `windchill-method-server`: the entry's own sample lines through
  `assert_registry_sample_scenario` (slug, match_type 17, 3 matched, whole-file sample).
- `windchill-method-server-named` / `-rolled` / `-renamed`: the committed
  fixture `tests/fixtures/format-detection/windchill-method-server.txt`
  (21 records + 30 continuation lines, scrubbed) staged as
  `BackgroundMethodServerESI-2507180624-9559-log4j.log`,
  `MethodServer-2507180627-9144-log4j.log.2025-07-18_3` and `app.txt`:
  21/30 matched/unmatched in all three; filename evidence
  `stem=mt17 ext=match date=- index=-`, `… date=match index=present`, and
  `stem=- ext=- date=- index=-` respectively.
- `scan-telemetry`: `entries: 15`.

Sabotage proofs (run directly against `ltl`, HARNESS-DESIGN § Proving a new
assertion can fail): one record's ` - ` broken → `matched_lines: 20` /
`unmatched_lines: 31`; roll date one day off the content → `date=mismatch`;
a nine-digit start-time token → no stem evidence. The `date_n`+`date`
build guard fires with its diagnostic.

## Surfaces touched

`ltl` (`%match_type_to_slug`, `%format_filename_index_re`,
`compile_format_filename_matcher()`, `format_registry_specs()`),
`tests/validate-format-detection.sh`, the fixture and `manifest.tsv`,
`docs/test-logs.md` (MethodServer section), `features/log-format-registry.md`
(`entries:` contract count, per-drop list). `--help` and `docs/usage.md`
enumerate no format names (the `-lf` usage error lists them at runtime), so
neither changes.

## Open items

- The stem requires the producer-true `-<yyMMddHHmm>-<pid>-log4j` tail. A
  hand-renamed `MethodServer.log` matches by content but carries no name
  evidence; whether the stem should also accept the bare service name is an
  architect call (the ThingWorx stem accepts bare names because that is how
  logback writes the live file; Windchill never writes one).
- Other Windchill processes (`ServerManager`, the Windchill DS / Info*Engine
  adapters) are believed to share this layout and naming; no specimen was
  available, so they are not declared (same rule as `alwayson-cxserver` in
  Drop 1.5).
