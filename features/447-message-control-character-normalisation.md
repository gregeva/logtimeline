# Feature: Control-character normalisation of extracted message text

## Overview

The messages table budgets its message column in **characters** and pads with
`sprintf "%-Ns"`. Both assume one character occupies one terminal column. A
control character inside the message breaks that assumption, so a row whose
character count is correct still overflows its column and pushes the Occurrences
cell off the line while every other row stays aligned.

This drop normalises control characters out of the message **at parse time**, at
the single point every ingest path has finished writing it and before anything
reads it. It is not a render fix and not a per-consumer fix: one normalisation,
one resolution surface, and every consumer of the message key receives the same
clean text without knowing the problem existed.

## GitHub Issue

[#447](https://github.com/gregeva/logtimeline/issues/447) — BUG: message
truncation counts characters, not rendered terminal columns — a TAB in the
message breaks row alignment.

Position 5 in the 0.18.0 delivery order
(`features/bin-counter-accuracy-and-observability.md` § D6). The position is
forced: this changes the message key, therefore consolidation grouping, therefore
what the drift baselines contain, so it lands after stage 4's re-bless rather
than between the stage-3 capture and the changes that capture measures.

## Sources

- `features/fuzzy-message-consolidation.md` — DD-06 (truncated-message cap) and
  the #158 precedent below; the similarity engine consumes the key this drop
  changes.
- `tests/HARNESS-DESIGN.md` § Render-invariant harnesses, § Self-documenting
  assertions, § Proving a new assertion can fail, § Invocation coherence.
- `features/bin-counter-accuracy-and-observability.md` § D6 — delivery order.

## What was measured before deciding

Reproduced on `release/0.18.0` with a Windchill Method Server fixture at
`--terminal-width 140`. With ANSI stripped, every messages-table row measured
138 characters; the row whose message carried one TAB measured 138 characters
and **145 terminal columns**. The overflow is exactly the tab-stop advance, and
the character count — the thing the code budgets against — is identical on both
rows, which is why nothing downstream detects it.

Three further defects surfaced from the same cause, each worse than the
misalignment the issue reports:

| Character | Observed effect |
|---|---|
| CR (0x0d) | The cursor returns to column zero and the rest of the row overwrites its own start. Message identity and the Occurrences value are both destroyed on screen while the byte count still measures correct. |
| ESC (0x1b) | Passes through ingest untouched and is executed by the terminal as an ANSI sequence, re-colouring everything printed after it. |
| US (0x1f) | Is the field separator of the per-message counter store (`"$category\x1f$log_key"`) and of the `-V message-grouping / cluster-membership` records. A raw one inside a message forges a key boundary; a synthetic cluster line was produced this way from a crafted log line. |

The messages CSV is affected too, and more sharply than "misaligned": a message
carrying a CR is written by `Text::CSV` as a **quoted multi-line field**, so one
logical record spans two physical lines. A conformant reader copes; `grep`,
`awk`, `sed` and every line-oriented consumer read it as two records.

## Locked decisions

### D1 — TAB expands to four spaces; other C0 characters and DEL are removed

TAB is the only control character with a defensible width, so it is preserved as
separation rather than dropped. It expands to a **fixed four spaces**.

A terminal does not render a TAB as any fixed width — it advances to the next
eight-column tab stop, so the cost depends on which column the tab lands in (the
measured case above cost seven). A fixed expansion is therefore not a
reproduction of terminal behaviour and is not intended as one: it is a stable
substitution that makes the key's character count equal its column count
regardless of where the message sits in the row.

Every other C0 control character (0x00–0x1f) and DEL (0x7f) is **removed**. None
carries display meaning, and each corrupts output in its own way per the table
above. Removal is silent — the two sides of a CR are joined with no trace — which
is the specified behaviour.

*Architect decision, 2026-08-27: both halves as specified in the issue, after the
tab-stop measurement was presented.*

### D2 — The normalisation happens once, at parse time

The normalisation sits in `read_and_process_logs()` at the point where every
ingest path has finished writing `$message` — the format registry's generated scan for all
fourteen formats, and both CSV assembly branches — and before anything reads it.

This is the whole design. Normalising at parse time means:

- no later path can reintroduce the problem, because no later path sees the
  original text;
- the message key, the table, the messages CSV, the consolidation grouping key
  and the verbose surfaces are all fed from one clean string, so none of them
  needs its own cleaning step;
- the in-message metric probes and the user-defined-metric masking, which both
  read and rewrite `$message`, operate on normalised text.

That single normalisation is the only behaviour change in `ltl`.

### D3 — The raw line is deliberately left alone

`-include`, `-exclude` and `-highlight` match against `$_`, the raw line, not
against the message. They are not normalised.

Those patterns are the user's to write: a pattern containing `\t` matches a log
line containing a tab, and that must keep working. Normalising the raw line at
the CR/LF strip would have been the shorter change and would have silently
altered what every user-supplied filter matches — a scope change this issue does
not ask for.

### D4 — Written inline and guarded, not as a sub

The normalisation runs once per matched line, so its shape is a hot-loop
decision, not a style one. It is written inline behind a guard:

```perl
if ( $is_line_match && defined $message && $message =~ tr/\x00-\x1f\x7f// ) {
    $message =~ s/\t/    /g if index( $message, "\t" ) >= 0;
    $message =~ tr/\x00-\x08\x0a-\x1f\x7f//d;
}
```

The first implementation was a named sub called unconditionally, and it cost
**+4.36% of total runtime** (+503 ns/line) on a 1.43M-line access log. That is an
unacceptable price for a cleanliness fix and was caught by measurement, not
review.

Two changes account for the recovery:

- **Inlining.** The sub call — argument passing, a lexical copy, a return-value
  copy — cost more than the two rewrites it wrapped. Inlining alone measured
  +117% throughput on a 1000-message loop.
- **Guarding.** `tr` in counting mode is a single character-class scan that
  modifies nothing. Virtually no log line carries a control character, so the
  common case pays one scan and rewrites nothing: a further +44%.

Nothing rewrites a string without a reason to. The tab substitution runs only
when the message actually contains a tab, and the delete then excludes `\x09`
because any tab is already gone.

| Arm | Median | vs baseline | Per line |
|---|---|---|---|
| baseline | 16.383 s | — | — |
| sub call, unguarded | 17.192 s | +4.36% | +503 ns |
| **inline, guarded (shipped)** | 16.514 s | **+0.80%** | **+92 ns** |

Order-balanced ABBA design, 8 pairs, positive in 7/8. **Single-order interleaving
was not sufficient** — the same code measured +0.44% and +1.99% in different
sessions, because within-arm spread (0.36 s) exceeds the effect (0.13 s). The
residual +92 ns/line is one scan of every message, which is the floor for any
implementation that must know whether a message is clean.

Full record: `tests/profile/results/447-control-char-normalisation/`.

### D5 — Gated on `$is_line_match`

A line no format recognised has no message to clean, so the normalisation is
gated on the same condition every consumer of the message already sits behind.

**This saves nothing measurable** — `-0.11%`, 3/6 pairs, even on a Connection
Server log where 502,133 of 999,883 lines are unmatched. An unmatched line's
`$message` is empty or undef and `tr` over an empty string is free, so the guard
was already skipping the work. The gate is kept because it states the intent
correctly, not because it pays.

It matters for a second reason, found while validating it. The record lexicals
are **not** reset per line: they are cleared as a side effect of the scan's
failed list-assignment matches, which set every capture target to undef. A
space-led line is rejected by the whitespace dispatch *before any block runs*, so
it performs no such match and `$message` still carries the previous matched
line's text. Message-key construction already sits behind `if( $is_line_match )`,
so no output was ever wrong — but normalising ahead of that condition would have
rewritten a value no longer in play.

### D6 — FATAL joins the log-level vocabulary

A line whose captured level is not in `@log_levels` is discarded by the per-line
category gate: read, matched against its format, then silently dropped. It counts
in LINES READ and not in LINES INCLUDED, and nothing tells the user.

**FATAL was not in the vocabulary.** The Windchill Method Server format emits it
— 14 lines across the corpus, including `MethodServer stopped`, a server
shutdown — and every one was being discarded. Found while reproducing this
issue's control-character case on a Method Server log.

FATAL is added to all four surfaces a category must occupy (the three named in
`features/395-wgm-client-log-format.md` § Log-category consistency, plus the
error rate):

| Surface | Change |
|---|---|
| `@log_levels` / `%log_level_set` in `ltl` | `FATAL-HL`, `FATAL`, ordered ahead of ERROR as the more severe level |
| `%colors` in `ltl` | red, as ERROR — both are failures |
| `tests/csv-output/rules/stats-columns.tsv` | `FATAL` and `FATAL-HL` rows, `int`/`level` family |
| Error-rate accumulation in `normalize_data_for_output()` | FATAL joins `ERROR|5xx|4xx` — it denotes a failure |

The statistics oracle (`tests/statistics-drift/oracle/calculate-reference.py`)
already listed FATAL in its own `LOG_LEVELS` filter, so the oracle had been
counting lines the tool discarded. That divergence was latent — no drift baseline
carries a FATAL line — and closes with this change. Its stale `ltl:NNN` comment
references were replaced with function names at the same time.

**This is not the whole gap.** The format patterns admit any `\w+` in the level
slot while the gate accepts 13 hard-coded names, so `CRITICAL`, `SEVERE`,
`WARNING` (java.util.logging's spelling of WARN), `NOTICE`, `ALERT` and
`EMERGENCY` are all matched and then dropped. None appears in the current corpus,
so none is a live defect. Two issues carry the rest, deliberately separated
because one is a list edit and the other is a redesign, and the cheap fix should
not wait on the expensive one:

- [#475](https://github.com/gregeva/logtimeline/issues/475) — the missing
  severity names are added to the recognised set, the same four-surface change
  this decision worked through for FATAL.
- [#476](https://github.com/gregeva/logtimeline/issues/476) — log levels are a
  property of the format that emits them, so they belong in the format registry
  beside each format's duration unit and time contract; a level seen but not
  registered is collected during the run and reported at the end, naming the
  format and the levels, rather than discarded in silence.

## Affected surfaces

All of these consume the message key and are therefore corrected by D2 without
any change of their own:

| Surface | Produced by |
|---|---|
| Messages table | `print_message_summary()` |
| Messages CSV (column 2 is the key verbatim) | `print_message_summary()` |
| `-g` consolidation grouping key and trigram similarity input | `consolidation_process_key()`, `get_consolidation_trigrams()` |
| `-V message-grouping / cluster-membership` records | `group_similar_messages()` |
| `%log_messages` and the `%log_messages_counters` composite key | `read_and_process_logs()` |

`ltl-index.csv` is **not** affected: `write_index_file()` writes file metadata
and numeric aggregates only, and its one free-text column is already
percent-encoded by `serialize_filters()`.

## Section contract

This drop adds no `-V` section and changes no existing one. The
cluster-membership records it asserts against are #462's surface, unchanged here;
what changes is that no message-derived key can any longer forge their `0x1f`
category/key boundary.

## Test coverage

`tests/validate-log-level-vocabulary.sh` — render-invariant harness over
`tests/fixtures/log-level-vocabulary.txt`, one line per level the Windchill
Method Server format emits. Asserts each level reaches the category table, that
LINES READ equals LINES INCLUDED (a shortfall is the count the gate discarded),
and that FATAL raises the error rate — measured by comparing a FATAL-and-ERROR
run against the same fixture with the FATAL line downgraded, which keeps the
assertion independent of the rate unit. The rate assertion runs at `-bs 1`, the
one place bucket size matters: at `-bs 1440` two failures over a day round to
0/min on both arms. Sabotage: removing FATAL from `@log_levels` fails exactly the
three FATAL assertions and leaves the other five green.

`tests/validate-message-control-characters.sh` — render-invariant harness
(HARNESS-DESIGN.md § Render-invariant harnesses) over
`tests/fixtures/message-control-characters.txt`, a seven-line committed fixture
carrying TAB, CR, ESC, US, vertical tab, form feed and backspace inside message
text alongside control-free baseline messages.

Three scenarios, eleven assertions:

- **`control-character-normalisation`** (`-g 60 -o`): table rows all occupy one
  identical terminal column count; no control character in the rendered table;
  none in the messages CSV; every CSV record on exactly one physical line; and
  no member key forging a unit-separator boundary in the cluster-membership
  records (a `cluster:` line carries exactly one separator, a `member:` line
  none).
- **`ungrouped-tab-expansion`** (no `-g`): with each message on its own row, the
  same column-count and control-character invariants plus the direct assertion
  that a source TAB renders as four spaces. Consolidation collapses the fixture
  to one wildcard row, so per-message text is only assertable ungrouped.
- **`unmatched-line-not-normalised`** over
  `tests/fixtures/message-control-characters-unmatched.txt`: two matched lines
  around one space-led line the whitespace dispatch rejects before any format
  block runs, so the record lexicals still carry the preceding line's text
  (D5). Asserts 3 lines read / 2 included and exactly two distinct message rows
  — an included count of 3, or a duplicated row, would mean the stale message
  was re-counted.

All three run `-bs 1440 -oe -ni` (§ Invocation coherence): no assertion reads
the time axis, so the coarsest bucket with empty buckets suppressed is the
correct shape.

**Sabotage proof** (§ Proving a new assertion can fail): with the normalisation
disabled, seven of the eleven assertions fail with their expected diagnostics.
Of the four that do not:

- the CSV one-record-per-line check passes because `Text::CSV` quotes the
  embedded CR rather than emitting a bare newline, so it was proven separately
  against a hand-doctored CSV carrying a raw embedded newline, where it fails as
  intended;
- the three `unmatched-line-not-normalised` assertions pass, because they cover
  the pre-existing `$is_line_match` gate on message-key construction rather than
  the normalisation itself. They were verified to pass with the D5 gate removed
  too — they are regression cover for the condition that makes D5 safe, not a
  test of D5.

## Out of scope

- **Stack-trace lines competing for Top-N slots** — the second half of the
  original report, split out to
  [#465](https://github.com/gregeva/logtimeline/issues/465). That is a new
  concept in the format registry with a per-line cost, not a normalisation.
- **Wide and combining characters.** The column-count assumption this drop
  repairs for control characters is also violated by East Asian wide characters
  and combining marks. No such case has been reported, and the fix would be a
  display-width measurement rather than an ingest normalisation. Not filed.
- **Log levels beyond FATAL that the gate discards.** The format patterns admit
  any `\w+` in the level slot; the gate accepts 13 names. `CRITICAL`, `SEVERE`,
  `WARNING`, `NOTICE`, `ALERT` and `EMERGENCY` are matched and then dropped with
  no notice. None occurs in the current corpus. Filed as
  [#475](https://github.com/gregeva/logtimeline/issues/475) (add the missing
  severity names) and [#476](https://github.com/gregeva/logtimeline/issues/476)
  (declare levels per format in the registry and report unregistered ones); see
  D6.
