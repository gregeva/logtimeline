# Feature: Windchill Workgroup Manager client log format (Issue #395)

## Status

Implemented on `395-wgm-client-log-format`, targeting release 0.17.0. Registry
entry `mt16`, user-facing name `windchill_workgroup_manager`, match_type 16. Decisions D54–D56
locked by the architect 2026-08-23.

## Overview

PTC Windchill Workgroup Manager (WGM) writes three client-side diagnostic
files — `genlwsc.log.N`, `uwgm_client.log.N` and `uwgm.log.N` — in one
self-describing line format. Each file opens with a header block declaring its
own schema (`columns "date time tz msgtype logid tid area message"`,
`columns_sep ": "`, `time_precision 1000`, `use_local_time NO`), followed by
data lines in that schema. This drop adds one declarative registry entry for
the shape, filename evidence for the three stems, the category mapping the
msgtype letters need to survive the read loop, a committed fixture and harness
scenarios. No hot-loop code changes; the registry does the work.

## Format contract

### Line shape

```
<YYYY-MM-DD>T<HH:MM:SS.mmm><zone>: <msgtype>: P<pid-hex>: T<tid-hex>: <area>: <message>
```

`<zone>` is `Z` or a numeric offset (see § *Zone forms*). Every other field is
separated by the literal `": "` the header declares. Verified
over all twelve UTC-form sample files (2,534,326 lines) and the four
local-offset files (7,143,655 lines): every line matches; there are
no continuation lines, no blank lines, no lines without a timestamp, no BOM.
Some messages end in a carriage return (HTTP response headers echoed into
trace lines) — that is message content under a `\r?\n` line ending, which the
read loop already strips.

| Field | Capture | Record field | Notes |
|---|---|---|---|
| date + time | `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}` | `timestamp_str` | The `Z` is matched outside the capture. `frac fixed3` strips the fraction at offset 19; the `T` separator is kept (the fixed-offset parser never reads offset 10). |
| msgtype | `[A-Z]` | `category_bucket` | Mapped through `wgm_msgtype` (D54). |
| logid | `P[0-9a-f]+` | `platform` | Process id with the `P` prefix the log prints. Captured for the record; no consumer today. |
| tid | `T[0-9a-f]+` | `thread` | Thread id with its `T` prefix. No `-N` suffix, so no thread-pool grouping is derived. |
| area | `[^ :]+` | `object` | Dotted component path; `#`-qualified for sessions and transactions (`uwgm.session1.act#…​.srvtxn#0`); `$default` on header lines. Never contains a space or a colon in the corpus, so the class stops at the field separator. |
| message | `(.*)` | `message` | Free text; freely carries further `: ` sub-structure (`UWGMCLNT_UI: UwgmApp::init Entered`, `$generic: columns "…"`). |

`instance`, `user`, `session`, `bytes`, `duration` are undef; `status_code` and
`metrics_observed` are 0. Occurrences only: no line-level duration, bytes or
count, `stats_eligible => 0`, `duration_unit => undef`.

### Time contract

`layout iso_ms`, `precision ms`, `tz utc`, `frac fixed3`. The epoch is
computed from the timestamp's own digits by fixed-offset arithmetic; the zone
marker sits past offset 19 and is never read, so the time axis is the wall
clock the file states, whichever zone form it uses.

### Zone forms (#512)

The producer writes the zone according to its header's `use_local_time`
declaration, and both forms are one entry:

| Header | Zone written | Example |
|---|---|---|
| `use_local_time NO` | `Z` | `2025-10-29T10:56:53.239Z` |
| `use_local_time YES` | numeric offset, hour **not** zero-padded | `2026-04-27T21:54:35.962+2:00`, `2026-04-30T13:29:13.168+0:00` |

The pattern matches the zone as `(?:Z|[+-]\d{1,2}:\d{2})` in a non-capturing
group: the offset is recognised so the line is claimed, and discarded because
nothing consumes it. A one- or two-digit hour and a signed offset are both
accepted; the offset form is therefore not strictly ISO-8601.

The entry keeps a single slug rather than becoming a variant group (architect,
2026-09-01): the two forms differ only in a zone that has no consumer, so a
member split would divide the format's identity on a distinction nothing
downstream can act on. `tz` stays `utc` and the zone is not captured into the
record; making the offset addressable would mean a fourteenth record field,
which is its own change if a consumer ever wants it.

### msgtype vocabulary (D54)

| Letter | Category | Observed meaning |
|---|---|---|
| `C` | `CONFIG` | header block (`$default: $generic: …`) |
| `D` | `DEBUG` | |
| `E` | `ERROR` | |
| `F` | `FINISH` | `… finished` (paired with `S`) |
| `I` | `INFO` | |
| `S` | `START` | `… started` (paired with `F`) |
| `T` | `TRACE` | |
| `W` | `WARN` | |
| `X` | `CREATE` | `… created` (paired with `Y`) |
| `Y` | `DESTROY` | `… destroyed` (paired with `X`) |

All ten letters occur in the corpus; the issue listed seven (`E`, `F`, `S`
were missing). A letter outside the table is left as captured and falls to
the category-vocabulary gate like any unknown level.

### Filename evidence (D55)

`stem (?:genlwsc|uwgm_client|uwgm)`, `ext .log`, `index dot_n`, `placement
after` (`stem ext[.N]`). Filename samples: `genlwsc.log.1`, `uwgm_client.log.1`,
`uwgm.log.1`, `uwgm_client.log`, `genlwsc.log`. No date component — the
producer never puts one in the name. The nested `Log_PROE_*/` directory is
path context, which D45 deliberately does not read.

### Scan-order constraint

`mt16` sits after the `connection_server` group and before `mt1gen` in static
order and declares no ancestors. It is an ancestor of `mt2` (RAC client),
whose `.*? \[[L: ]*([^\]]*)\]` tail accepts any line carrying a bracketed
token — 51,757 of the corpus lines (2.0%). The bracket-bearing sample
(`UWGMLIB_PREFERENCES: [AutoCAD]`) is the executable cross-shadow proof that
derives the constraint; `mt2` declares `expect_ancestors => [mt1std,
connection_server, mt16, mt1gen]`.

## Locked decisions

### D54 — msgtype letters map to categories: severity letters to the shared levels, lifecycle letters to their own identity (LOCKED 2026-08-23)

The read loop drops any line whose category is not in `@log_levels`, so the
raw letters cannot be the category — every WGM line would be matched and then
silently discarded. The mapping is a per-line hash lookup (`wgm_msgtype`,
one named transform primitive). `D/E/I/T/W` become the shared
`DEBUG/ERROR/INFO/TRACE/WARN`, so error rates and highlight semantics work as
for every other format. `C/X/Y/S/F` have no severity; they become `CONFIG`,
`CREATE`, `DESTROY`, `START`, `FINISH` — five new members of the vocabulary,
each with a colour and `-HL` variant, following the GC precedent (#382 D42:
level is identity, not severity). Folding them into an existing level was
rejected: it loses the lifecycle pairing (`X`/`Y`, `S`/`F`) that is the most
useful structure these logs carry, and no severity is an honest fit. Only
categories present in a file become columns, so the five new names appear
only for WGM input. Their CSV column rules are declared in
`tests/csv-output/rules/stats-columns.tsv` in the same change.

Colours follow the meaning of the verb, not the order the categories were
added (architect, 2026-08-23) — new categories that mirror a log's own
categorisation are the intended process, and the colour must say what the
event means:

| Category | Colour | Rationale |
|---|---|---|
| `DESTROY` | red (`0;31`) | The most destructive event: an object is torn down. Red is the palette's severity ceiling (`ERROR`, `5xx`, `Pause Full`). |
| `FINISH` | green (`0;32`) | A positive outcome: work completed. Green is the palette's success colour (`INFO`, `2xx`, `Pause Cleanup`). |
| `CREATE` | cyan (`0;36`) | The beginning of an object's life — a cool, opening colour, and not otherwise used by a level, so creation stands out from every severity. |
| `START` | blue (`0;34`) | The beginning of an activity on an existing object; a cool colour adjacent to `CREATE` (both are beginnings) but distinct from it so the create/start and destroy/finish pairs read separately. |
| `CONFIG` | magenta (`0;35`) | Neutral, informational self-description (the header block). Magenta is what the palette already uses for the non-severity informational class (`TRACE`, `Pause Young`). |

The two beginnings share the cool side of the palette and the two endings
the warm side, so `CREATE`/`DESTROY` and `START`/`FINISH` pairs are
visually paired.

### D55 — One registry entry with a multi-stem filename family, not a variant group (LOCKED 2026-08-23)

Variant groups (D47) exist for producers that share a shape but differ in
*semantics* — date layout (Connection Server vs Integration Runtime) or unit
(Tomcat vs httpd `%D`) — where picking the wrong member changes what the
numbers mean. The three WGM files share the shape *and* the semantics: same
columns, same UTC contract, same vocabulary; they differ only in which
subsystem writes them and what the `area` values are. Three members would buy
three user-facing names at the cost of three slugs, three sample sets, and
the ambiguity note firing on any renamed file for a "consequence class" that
does not exist. The user already sees which file is which in the file list;
the `area` values say the rest. One entry whose stem alternation covers the
family is the honest model; the `filename_evidence:` line in `-V` still names
which stem matched. Note that the in-file `log_base_name` does *not*
discriminate either: `uwgm.log.1` declares `log_base_name "uwgm_client"`.

### D56 — Extraction is capture-only apart from the msgtype map (LOCKED 2026-08-23)

No timestamp normalisation (`t_to_space`) and no `strip_trailing_ws`: the
fixed-offset parser reads around the `T`, the GC entry already keeps its `T`
without consequence, and the trailing space some trace messages carry is
invisible in every rendered surface. Each transform is a per-line cost on
files that run to 842k lines; none of these buys the analyst anything.

## Verification (2026-08-23)

Corpus: the twelve files under `logs/WGM/` (gitignored; `docs/test-logs.md`).

| Check | Result |
|---|---|
| Pattern over every line of every file | 2,534,326 / 2,534,326 matched |
| Lines also accepted by `mt2` | 51,757 (2.0%) — hence the ancestor constraint |
| D24 load-time gates (samples, parity, cross-shadow, filename samples, whitespace dispatch) | pass on every run |

`ltl --disable-progress -ni -bs 1440 -oe -n 1 -osum -V format-detection -V benchmark-data <file>`,
one file per stem (the smallest triple) plus the largest `uwgm_client`:

| File | lines | matched | included | filename_evidence | stderr |
|---|---|---|---|---|---|
| `genlwsc.log.1` | 7,766 | 7,766 | 7,766 | `stem=mt16 ext=match date=- index=present` | clean |
| `uwgm_client.log.1` | 155,541 | 155,541 | 155,541 | same | clean |
| `Log_PROE_*/uwgm.log.1` | 31,756 | 31,756 | 31,756 | same | clean |
| `uwgm_client.log.1` (second set) | 474,278 | 474,278 | 474,278 | same | clean |

`included = matched` is the proof of D54: the category gate passed every
line. Sabotage: removing `CONFIG` from `@log_levels` leaves `matched_lines`
at 44 on the fixture and drops `lines_included` to 33 — caught by the
`wgm-client` scenario's `lines_included` assertion and by nothing else;
disabling the transform is caught earlier by D24 gate 2 (expected records).

Harness: `tests/validate-format-detection.sh` — scenarios `wgm-client` (9
assertions) and `wgm-filename-family` (6 assertions) green; `entries: 14`.
CSV rules: the WGM STATS CSV is refused by the previous
`stats-columns.tsv` (`unknown column FINISH`) and accepted by the updated one.

## What the issue got wrong about the data

- msgtype vocabulary is ten letters, not seven: `E` (error), `F` (finish),
  `S` (start) occur in every `uwgm.log.1` and in most `uwgm_client.log.1`.
- `log_base_name` does not identify the subsystem: `uwgm.log.1` declares
  `"uwgm_client"`. Only the file name separates `uwgm.log` from
  `uwgm_client.log`.
- Areas are not purely dotted: session/transaction areas carry `#`
  qualifiers (`act#…`, `srvtxn#N`, `merge#N`) — thousands of distinct such
  values across the corpus.
- Some lines end `\r\n` (HTTP headers echoed into trace messages); harmless.

## Log-category consistency

A log category lives on three surfaces that must agree: `@log_levels` in
`ltl` (the read loop keeps only lines whose category is listed), `%colors`
(rendering; the `-HL` twin derives automatically) and
`tests/csv-output/rules/stats-columns.tsv` (the CSV structural validator
refuses any column it does not know). A new category updates all three in the
same commit. Found while adding the WGM categories: the four #382 GC
categories (`Pause Remark`, `Pause Cleanup`, `To-space exhausted`, `Using G1`)
had no rules rows; closed here. `resolve_csv_column_family()` now resolves
every category through the `@log_levels` lookup alone — its `Pause
(Young|Full)` and `[1-5]xx` special cases duplicated entries already in the
list.

What enforces it: the `validate-csv-output.sh` scenario `gc-g1-categories`
(`tests/fixtures/gc-g1-categories.txt`, seven lines carrying all six GC
categories, `-bs 1440 -oe -n 1`) drives every GC category through the
validator, so a category reaching the CSV without a rules row fails the
harness; the WGM categories are covered the same way by the `wgm-client`
fixture through the format-detection harness and by the rules rows declared
above. A structural assertion that every non-`empty`, non-rate member of
`@log_levels` has a rules row is not built: nothing exposes the vocabulary
outside the Perl source (no `-V` key lists it), so it would need new
machinery — a `log_levels:` key in the `csv-output` section plus a one-line
harness check is the cheapest option if wanted.

## Success/failure classification (#510, 2026-09-01)

**The entry declares no classification: it inherits the global default —
failure on `category_bucket ^(?:ERROR|FATAL|CRITICAL)$`, no success
criterion — and carries no event-ledger flag.** Only `ERROR` is reachable
from the letter vocabulary (D54); there is no fatal code. The survey below is
why, and in particular why the structured records that *do* state outcomes
are not used.

### Corpus surveyed

All 17 WGM-format files across the four capture sets in `docs/test-logs.md`
§ *WGM/*, 9,677,981 matched lines. Letter totals: `D` 5,927,621 · `I`
3,145,754 · `T` 437,198 · `E` 80,251 · `S` 19,019 · `F` 19,019 · `X` 17,170 ·
`Y` 17,043 · `W` 14,719 · `C` 187.

### Provenance of the letter vocabulary

The header block declares the schema (`columns`, `columns_sep`,
`date_format`, `time_format`, `time_precision`, `log_base_name`,
`use_local_time`, `verbose_level`) but **never names the msgtype letters** —
the D54 mapping is inferred from message content, and the lifecycle half is
evidenced without exception across the corpus:

| Letter | Mapped to | Lines | Messages ending in the matching verb |
|---|---|---|---|
| `X` | CREATE | 17,170 | 17,170 (100%) end `… created` |
| `Y` | DESTROY | 17,043 | 17,043 (100%) end `… destroyed` |
| `S` | START | 19,019 | 19,019 (100%) end `… started` |
| `F` | FINISH | 19,019 | 19,019 (100%) end `… finished` |

`S` and `F` are exactly equal; `X` exceeds `Y` by 127, the objects still
alive when logging stops. The severity letters `D/E/I/T/W` have no comparable
in-log proof and are read as the conventional initials.

### Where outcomes are actually stated

Two structured record families appear in the message as
`IndexLogging: Ver-0.1 <id>$<Tag>…</Tag>`:

| Record | Count | Outcome vocabulary |
|---|---|---|
| `$<ContentDownloadFinish>` | 65,979 | `…_RETRY` 37,351 · `…_SUCCESS` 24,651 · `…_ALREADY_CACHED` 3,202 · `…_FAIL` 437 · `…_RETRY_IMMIDIATELY` 338 (the producer's spelling of "immediately") |
| `$<ActionState>` | 1,543 | `finished: SUCCEEDED` 1,537 · `started` 6 — **no failed value in any capture** |

A download record is emitted once per action tracking the content, so the
same attempt appears under each concurrent action (two dominate a session);
records are distinct on content + attempt + status + action.

### Why failure rests on `ERROR` alone

Measured on one session file (13,742 finish records, 5,298 distinct failed
attempts):

- `E: Download failed, deleting all streams` — 5,345 lines, one per failed
  attempt; the first finish record following an `E` on the same thread is
  `RETRY` 4,882, `FAIL` 220, `RETRY_IMMIDIATELY` 167.
- `W: HTTP Download failed. Marked (immedidate) retry for:` — 5,125 lines,
  **all 5,125 paired one-to-one with an `E` line on the same thread** (89.4%
  within 4 lines, 100% within 20). The `W` is a second announcement of the
  retry-marked subset, not an alternative to the `E`; the 5,345 − 5,125 = 220
  difference is exactly the terminal `FAIL` cases, which are not retried.

So `ERROR` already counts every failed download attempt exactly once.
Classifying `WARN` as a failure would double-count the retried subset, and
classifying the download records as failures would double-count every failed
attempt again — in one capture exactly twice (27,542 `E` lines against 27,542
`RETRY` records). Failure therefore stays the inherited `ERROR` criterion,
with `WARN` out.

### Why there is no success criterion

`…_SUCCESS` and `…_ALREADY_CACHED` are genuine producer statements that a
download completed, and nothing else in the file reports them — a successful
attempt has no severity line at all. They are nonetheless not declared as
success, because **they are emitted at `D` (DEBUG)**: a reliability figure
that exists only when the client is running at debug verbosity is not a
figure this tool can offer for the format (architect, 2026-09-01). The same
applies to `$<ActionState>finished: SUCCEEDED`, which is emitted at `I` but
covers 1,543 records against 9.7M lines and has no failed counterpart in any
capture, so it cannot support both sides of a ratio.

Establishing success for this format needs different logs from the producer,
not a different criterion here. For the same reason the entry is not an event
ledger: the download sub-stream has maximal coverage of download attempts,
but the file as a whole is not a ledger of the operations it describes.

## Open items

- The `S`/`F` and `X`/`Y` pairs are natural inter-line duration sources
  (`Server Transaction started` → `finished` on the same `srvtxn#` area);
  out of scope here, noted for the derived-metrics phase.
- No `-V` section exposes per-category counts; the msgtype mapping is
  asserted through `benchmark-data`'s `lines_included`.
