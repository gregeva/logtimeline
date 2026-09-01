# Filter and highlight criteria for success and failure (#455)

Status: **implemented** — requirements and naming locked in dialog with the architect
(2026-09-01); delivered on branch `455-success-failure-filter-highlight-criteria`
the same day. Issue: #455. Prerequisite classification substrate: #453 (delivered,
`release/0.18.0`); percentage columns and reconciliation: #452 (delivered).

## Requirement

Success and failure — the classification a log format declares (#453) — become
available as **filter** and **highlight** criteria, on the same footing as the
existing members of those families:

- A success/failure **filter** discards lines, and every guarantee the filter family
  carries applies unchanged: filters affect all computed statistics.
- A success/failure **highlight** marks a subset within the full population and
  changes nothing about which entries are analysed.
- Excluding both success and failure leaves exactly the unclassified remainder on
  screen — the answer to the unclassified-lines notice's implicit question.

The reason an entry matches a highlight condition does not matter — regex, value
threshold, or classification result. A row matching goes into the highlight
counters and is drawn in the highlight colour, exactly as today.

## Locked decisions

### D1 — Six new options, fully symmetric, singular nouns

| Option | Short | Meaning |
|---|---|---|
| `--include-failure` | `-if` | Only lines classified as failure are included in the results |
| `--exclude-failure` | `-ef` | Lines classified as failure are dropped from the results |
| `--highlight-failure` | `-hf` | Failure-classified entries are highlighted |
| `--include-success` | `-is` | Only lines classified as success are included |
| `--exclude-success` | `-es` | Lines classified as success are dropped |
| `--highlight-success` | `-hs` | Success-classified entries are highlighted |

Singular forms (`-failure`, not `-failures`), matching the existing surface
(`--hide-session`, `--hide-classification`).

### D2 — Pattern-file options renamed to make room

`--exclude-file`/`-ef` → `--exclude-pattern-file`/`-epf`,
`--include-file`/`-if` → `--include-pattern-file`/`-ipf`,
`--highlight-file`/`-hf` → `--highlight-pattern-file`/`-hpf`.
The new classification surface takes priority over the pattern-file options for the
short forms. Renames apply everywhere — every option surface, all documentation on
filtering and highlighting. The literal-substring matching contract of the
pattern-file options (lines are matched as literals, not regex) survives the rename
unchanged.

**Hard break, no aliases.** The old names (`--exclude-file`, `--include-file`,
`--highlight-file`) are not kept as aliases and fail as unknown options; the change
is documented in the release notes, and the help outlines the usage. (Same
disposition as #432, metric aggregate naming.)

### D3 — `--hide-session` keeps its long name; short form `-hs` → `-hses`

Frees `-hs` for `--highlight-success`.

### D4 — The **expose** verb family, `x` prefix

`--include-session`/`-is` → `--expose-session`/`-xs`;
`--include-query-string`/`-iqs` → `--expose-query-string`/`-xqs`.

"Expose" = bring into the message grouping key data that grouping would otherwise
not show — session is not natively part of the message, so the option brings forth
something otherwise invisible. The verb is chosen to extend to hidden or calculated
data in the future; the `x` short-form prefix is reserved for this family (it was
entirely unclaimed). This frees `-is` for `--include-success` and makes the include
verb mean one thing.

### D5 — Count is spun out to #514, not part of this feature

Count is the same kind of thing as the expose family — surfaced data — but making
its capture, masking and display explicit via `--expose-count`/`-xc` (off by
default) changes default behaviour and carries its own open question (whether
count survives at all, given user-defined metrics). That is its own enhancement:
**#514** (count capture and display become explicit via `--expose-count`, off by
default). This feature does not touch `--include-count`, `--hide-count`, or count
behaviour. Not a gate in either direction.

### D6 — Criterion semantics

- `--include-failure`: only lines classified as failure are matched and included in
  the results. Likewise `--include-success` for success.
- `--exclude-failure`: lines classified as failure are dropped and not included in
  the results. Likewise `--exclude-success`.
- `--highlight-failure` / `--highlight-success`: counts, messages, etc. classified
  with that outcome become highlighted — via the same mechanism, counters, and
  colour as every other highlight condition. No new marking vocabulary.
- **Lines that classify to neither success nor failure are untouched by all six
  options.** On a format that declares no rule for the named outcome (or declines
  classification entirely), the option simply matches nothing / drops nothing — no
  error, no notice, no special-casing.
- **Unclassified is not itself selectable.** The unclassified remainder is reached
  by excluding both success and failure. No `-*-unclassified` options.
- Consumers read the classification outcome the format registry produced (#453 D13
  — the decision that a consumer never re-derives an outcome from the raw fields);
  these criteria select on it, they never re-test the line.

### D7 — Filters join the filter surfaces; highlights do not

The new **filter** options participate in everything the filter family
participates in: active-filter detection and the index-cache filter signature (a
run filtered on outcome must never reuse a selection cached under different
filters — the index must pick up the new `-es`/`-is`/`-ef`/`-if` filtering
options), and — when #454 (notice that statistics describe a filtered subset)
lands — they are discarding filters under that notice. The **highlight** options,
per the precedent locked in #312 (numeric criteria as highlight: highlight options
are not filters), change no filter surface and no index signature, and sit on
#454's non-trigger list.

Existing `ltl-index.csv` files are left alone: no migration and no compatibility
handling for rows written under the old pattern-file option tokens.

### D8 — The verb map

After this change each verb means exactly one thing across the CLI:

| Verb | Meaning |
|---|---|
| include / exclude | line filtering (`--include <regex>`, `--include-pattern-file`, `--include-failure`, …) |
| highlight | mark within the full population |
| expose | bring hidden or calculated data into the message grouping key (`x` prefix) |
| mask | remove variability from the grouping key (`--mask-uuid`) |
| hide / show | column visibility |

## Consequences to record (release notes / migration)

- **Silent meaning changes, not errors:** `-hs` today means hide-session and will
  mean highlight-success; `-is` today means include-session and will mean
  include-success; `-ef`/`-if`/`-hf` switch from pattern files (taking a filename)
  to failure criteria (taking none). Existing scripts and `LTL_CONFIG` values using
  these short forms change behaviour rather than failing. Release notes must call
  this out prominently.
- The `LTL_CONFIG` additive-options list changes (`-if, -ef, -hf` → the
  pattern-file replacements) and its help paragraph is updated.
- The help/docs prose pairing highlight criteria as "`-h`/`-hf`" and include as
  "`-i`/`-if`" becomes factually wrong and is rewritten, not merely renamed.
- The persisted index filter signature carries pattern-file tokens under their old
  names in existing `ltl-index.csv` files; those files are left alone (D7).

## Acceptance criteria

Derived from the requirement before implementation; each triaged
assertable / unassertable / unknown per `docs/test-driven-development.md`.
Enforcing harness: `tests/validate-outcome-criteria.sh` (AC1–AC6, AC9, and the
rejection/acceptance halves of AC7/AC8); option-surface parity for AC7 is
`tests/validate-help-content.sh`. AC3 runs on
`tests/fixtures/diagnostics-classification-overlap.txt` (2 of 4 lines
unclassified) — the crafted-fixture route; the #483 GC-format criteria remain a
future richer source. AC4's visual half was verified on a real access log
(highlighted messages panel, `(HL)` category row, highlight count equal to the
failure count, population unchanged).

- **AC1** (assertable): on an access-log fixture, `--include-failure` leaves only
  failure-classified lines in every surface — lines included, summary counts,
  bucket and message CSV — and `--include-success` the same for success.
- **AC2** (assertable): `--exclude-failure` removes the failure-classified lines
  from all computed statistics: lines included, per-bucket and per-message counts,
  and the classification counters themselves (failures report 0 after exclusion).
- **AC3** (assertable): `--exclude-failure --exclude-success` leaves exactly the
  unclassified remainder: lines included equals the unclassified count of the
  unfiltered run. *Fixture gate:* needs an input producing non-zero unclassified
  on a classifying format — #483 (GC-format classification criteria) is the live
  candidate; until then a crafted fixture on an access-log format serves.
- **AC4** (assertable + visual): `--highlight-failure` marks failure-classified
  entries **via the existing highlight mechanism** — the same tagging, counters,
  HIGHLIGHTED summary row and highlight colours as `-h <regex>` — and the analysed
  population is byte-identical with and without it. As a visual surface, the
  rendering is verified by looking at output on real data, not by grepping escape
  sequences.
- **AC5** (assertable): highlight criteria still AND-compose — with several
  highlight criteria given, an entry highlights only if it satisfies all of them,
  classification criteria included.
- **AC6** (assertable): a run with an outcome filter does not reuse an index-cached
  selection from a run without it (and vice versa).
- **AC7** (assertable): option-surface parity — every added and renamed option has
  its short form, `--help` row and `docs/usage.md` row; the retired names are
  rejected as unknown options. (`tests/validate-help-content.sh` is the enforcing
  harness.)
- **AC8** (assertable): `-hses` hides the Sessions column; `--expose-session`/`-xs`
  and `--expose-query-string`/`-xqs` behave exactly as the options they rename.
- **AC9** (assertable): all six options are inert on lines that classify to
  neither outcome, and produce no error and no output change on a format that
  declares no rule for the named outcome beyond what D6 specifies.

## Open items

None. The former open items are resolved: hard break for the old pattern-file
names (D2); existing index files left alone, new filters enter the signature (D7);
count spun out to #514 (D5); and sequencing against #478 (highlight bookkeeping on
the hot path) is decided — this feature is not gated on it and lands first; #478
carries a comment describing the option shape this feature brings.

## Findings during implementation

- **F1 — summary shares vanished under outcome filters** (architect bug report,
  2026-09-01, during testing): the run summary's classified-row shares were
  gated on the observed success count, so `-es`/`-if` (failures-only remainder)
  dropped them while the per-bucket columns still read 0%/100%. The suppression
  exists for formats that declare no success rule (classifying only errors) and
  is a test of the declared rules, not the surviving data — fixed by gating on
  `$cls_success_declared`; #452's D10 (eligibility gating consistent across all
  surfaces) carries the amendment.

## Related record

- #453 (per-variant success/failure classification and the event-ledger property)
  — supplies the classification these criteria select on; its D13 forbids
  re-deriving outcomes; its D16 orders classification before filtering and
  highlighting in the per-line flow, which is what makes these criteria expressible
  in the existing families.
- #452 (success/failure percentage columns and reconciliation) — its counters are
  incremented at the include point, so they follow these filters like every other
  statistic; its feature doc is the live record of the classification `-V`
  surfaces.
- #454 (filtered-subset statistics notice) — the new filters are discarding
  filters under it; the new highlights belong on its non-trigger list.
- #456 (per-message success/failure indicator) — sibling consumer of the same
  classification; must agree with this feature on the three-state vocabulary.
- #483 (classification criteria for the Java G1 GC format) — names this feature as
  a consumer; candidate fixture source for AC3.
- #312 (numeric criteria as highlight, not just filter) — the precedent template
  for the highlight side, including "highlight options are not filters".
- #230 (filter/highlight truth-table harness scoping) — the owning record for the
  filter grammar and the literal-vs-regex pattern-file distinction.
- #20 (configuration directory for pattern files) — its premise references the
  pattern-file options being renamed here.
