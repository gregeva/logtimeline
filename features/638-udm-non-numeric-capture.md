# #638 — A user-defined metric capture that is not a number is recorded as a fabricated value

Sub-issue of #629 (defects with a user-defined metric using a custom regex and
capture group); umbrella record `features/629-udm-custom-regex-defects.md`.
Owning area: `features/user-defined-metrics.md`.

## Requirement

A capture that is not a number never becomes a recorded value and never prints
a runtime warning, and the user can tell when a metric's captures were not
numbers.

## Findings

Measured on release/0.18.5; identical on release/0.19.0.

- **Code path.** In the `## USER DEFINED METRICS CAPTURE` block of
  `read_and_process_logs()`, the value is `defined $1 ? $1 : <whole match>`.
  Counting aggregations (count, distinct, ratio, rate, drate) keep the raw
  string and leave early, as #313 (counting aggregations) intends. Numeric
  aggregations reach `my $raw_value = $matched_value + 0;  # Ensure numeric`;
  the coerced number then goes through delta/idelta, the unit converter, and
  every accumulator.
- **Fixture: seven lines of an access log, one per minute**, capturing `42`,
  `12abc`, `abc12`, `abc`, an empty value, `_:_100`, `7`, run with
  `-ni -bs 1 -V udm-specs -udm 'v::sum:/v=(\S*)/'`: five runtime warnings,
  `produced: occurrences=7 sum=61 min=0 max=42`. Two values were observed
  (42 and 7); `12abc` was recorded as 12 and four captures as 0.

  | Spec | `produced:` | Shows |
  |---|---|---|
  | `v:B:max`, `v:ms:min` | `min=0 max=42` | the fabricated 0 passes the converter and `min` reports it |
  | `v:k::` | `sum=61000 min=0` | the multiplier applies to coerced values |
  | `v::delta` | `occurrences=6 sum=-35 min=-30` | coerced 0s enter the delta chain |
  | `v::idelta` | `occurrences=4 sum=7` | drops to a coerced 0 are discarded as counter resets |
  | `v::distinct`, `v::count` | `occurrences=7`, no warning | raw strings kept, including the empty one |

- **Masking.** Non-numeric text (`abc`, ` : 100`) is masked like a number. An
  empty capture makes `s/\Q$matched_value\E/?/` an empty pattern, which Perl
  treats as "reuse the last successful regex": what gets masked then depends on
  which regex last matched.
- **CSV column path** (`-ucm`): an empty cell is skipped, but `n/a` is recorded
  as 0 and `5ms` as 5, with warnings; same coercion line.
- **Default patterns cannot produce this.** `parse_udm_configs()` builds the
  name and token-key patterns from `my $number = qr/-?\d+(?:\.\d+)?/;`; only a
  `/regex/` spec or a CSV column can yield non-numeric text.

## Records that bear on it

`features/user-defined-metrics.md` has no decision on a non-numeric capture for
a numeric aggregation. #443 (UDMs fail silently): D2, "the group is a narrowing
device … the tool does not second-guess an explicit declaration"; D3, the run
never stops; D4, speculative guesses are never shown; D7, no new counters on
the hot path, the zero-match notice is derived after the read loop; D8/D9, the
one notice shape `Note: -udm '<spec>': no metrics produced from matching
lines`. #313 Risks names this class: "String leakage into numeric sites …
produces Perl 'isn't numeric' warnings".

## Existing number shapes

No shared "is this a number" sub exists. Near-duplicates: `$number` in
`parse_udm_configs()` (the UDM value vocabulary); `$decimal` in the `-bs` block
of `adapt_to_command_line_options()` (accepts a leading dot); the duration
guard in `read_and_process_logs()`
(`$duration !~ /^[0-9]+(?:\.[0-9]+)?$/`, which treats a non-number as
unobserved, silently); CSV epoch detection `/^\d+(\.\d+)?$/`.
`convert_duration_to_ms()` and `convert_bytes()` check definedness only, so
validation has to precede the converter.

## Candidate designs

- **Skip the observation.** A capture that does not fully match the number
  shape records nothing, leaves delta state alone and is not masked. The
  duration guard is the precedent. A spec whose captures were all rejected is
  already caught by the zero-match notice; telling the user about a partial
  rejection needs a count on the reject path, which #443 D7 (no new counters
  on the hot path) rules out unless changed.
- **Read the first number inside the capture.** ` : 22440` gives 22440 and the
  reported spec works as written, but `abc12` gives 12: the kind of guess
  #443 D2 and D4 exclude, and the capture group stops being the value boundary.
- **Reject at parse time.** Whether a regex captures digits cannot be proven
  from the spec (`(.+)` is legitimate on numeric data); at most a hint inside
  the zero-match notice, showing a sample rejected capture.

Any of these also settles the empty-capture masking hazard and the CSV cell
path, which share the coercion line.

## Decisions

- **D1 — A capture that is not entirely a number is skipped for that metric.**
  For a numeric aggregation (`sum`, `min`, `max`, `mean`, and the
  `delta`/`idelta` transforms), a capture such as `abc`, `12abc`, ` : 22440` or
  an empty capture records nothing, leaves the delta state alone, prints no
  warning, and is not masked in the message. Clean numeric captures and the
  built-in name and token-key patterns are unchanged. **Whether a capture is
  usable depends on the aggregation function**: a counting aggregation
  (`count`, `distinct`, `ratio`, `rate`, `drate`) counts values rather than
  doing arithmetic on them, so `abc123` is a relevant value there and is
  counted as today; under `sum`, `min`, `max`, `mean`, `delta` or `idelta` it
  is not a number and is skipped.
  Rationale: reading a number out of the capture (`abc12` → 12) is the guess
  #443 D2 (the capture group is the value) and D4 (no speculative guesses)
  exclude; the duration guard in `read_and_process_logs()` already treats a
  non-numeric duration as unobserved. Consequence accepted: a pattern such as
  `(.+)` that spans a separator produces nothing until the capture is narrowed
  to the number.
- **D2 — The way to avoid the skipped case is taught by example.** The `-udm`
  example in `--help` and in `docs/usage.md` shows a pattern whose capture is
  narrowed to the digits where a separator sits between the key and the value
  (the shape of `/dataQueue size\D*(\d+)/`), so the capture holds the number
  and nothing else. The `/regex/` row of `docs/usage.md` states that for a
  numeric aggregation the capture must be a number. (Architect's instruction:
  the associated example makes its way into, or updates, the help usage
  examples.)
- **D3 — A partly skipped `/regex/` metric is reported, with its share.** For
  each `/regex/` metric, the run counts the lines where the pattern matched and
  the value was recorded, and the lines where the pattern matched but the
  capture could not be used by the aggregation function (D1). Only when at
  least one line was skipped does one informational notice for that metric go
  to stderr after the read; a metric whose every matched line was recorded
  prints nothing. The notice giving both counts and the skipped share as a percentage, so the user
  can tell one or two stray lines from half the population and knows to revise
  the pattern. Rationale (architect): a pattern that matches but whose capture
  is not deterministic extracts only part of the population, and that must not
  happen silently; a metric that produces nothing already speaks through the
  zero-match notice, but a partial extraction had no signal at all. Scope:
  `/regex/` metrics, the only extraction where the user writes the capture.
  This narrows #443 D7 (no new counters on the hot path,
  `features/user-defined-metrics.md`): a count is kept for the matched-but-
  unusable case. Constraint: the two counts describe the same population, the
  lines that reach accumulation after the include/exclude, time-window and
  numeric filters; the capture runs before those filters, so a skip is counted
  only once the line is retained.
- **D4 — The recorded count comes from the existing model; the skipped count
  exists only once something is skipped.** The recorded figure is the
  `produced` occurrences already derived after the read loop from the
  per-bucket accumulators (#443 D7); nothing new is counted for it. The skipped
  count is created for a metric the first time one of its lines is skipped: no
  counter is declared, allocated or incremented for a metric that never skips,
  so a normal run carries no memory or per-line cost for it. `-V udm-specs`
  shows the skipped figure only for a metric that has one. Rationale
  (architect): #443 D7 guards against the memory and processing cost of
  standing counters across many metrics that in a normal run never move; a
  counter that exists only when it has something to say does not carry that
  cost.
- **D5 — `-V udm-specs` reports what the run actually did, and its defects
  are fixed here.** The section is the introspection into how the code ran
  against the data; a wrong value there leads to a wrong reading of the run,
  which is not acceptable. Two defects found during #629 are in scope of this
  issue:
  - `source=` is computed in `udm_read_as()` from the run-global
    `$csv_detected` and the last CSV header read, so it describes whichever
    file was read last: a run whose values all came from log lines reports
    `source=csv:unbound` when a CSV file sorts last.
  - On a run that reads a CSV file, a metric declared with unit `B` is shown as
    `unit=b(bytes)`; `KB`, `ms` and `k` are shown correctly, and `B` is shown
    correctly on a run without CSV input. Minimal reproduction: a two-line CSV
    with no `timestamp` column and `-udm "q:B:max:/q=(\d+)/"`. Root cause,
    found after D5 was recorded: CSV input is not involved. In
    `parse_udm_configs()`, `%byte_unit_canonical = map { lc($_) => $_ } keys %byte_units`
    folds `B`/`b` and `kB`/`KB` onto the same lower-case key, so which spelling
    wins depends on Perl's per-process hash order. Measured over 20 runs per
    unit: `B` rendered `B` 24 times and `b` 16 times per output line, on CSV and
    plain log input alike; `KB` resolved to `KB` (1024) or `kB` (1000) at
    random, so `-udm 'q:KB:max'` over `q=1000` reported `max=1024000` on one
    hash seed and `max=1000000` on another, with CSV columns `q_KB_*` or
    `q_kB_*`. This is #608 (byte unit resolves nondeterministically), closed
    and fixed on release/0.19.0 by one byte-unit ladder in which `KB` is the SI
    kilobyte (1000). It is present on release/0.18.5. Disposition
    (architect): the fix belongs to release 0.19.0, where #608 (a child of #622,
    the redundant-logic-surfaces refactoring) already delivered it (PR #635,
    merged into release/0.19.0; `B` and `b` render `B` on every run there). No
    new issue, and the unit item leaves this issue's scope; release 0.18.5 is
    not given the fix.
  Any `-V udm-specs` key change follows `tests/HARNESS-DESIGN.md` and updates
  the section contract in `features/user-defined-metrics.md` in the same
  commit.

- **D6 — The written forms of a number that are accepted (architect,
  2026-09-30).** For a numeric aggregation a capture is a number when the
  whole capture is written as `42`, `-5`, `+5`, `1.5`, `.5`, `5.`, `1e3` or
  `1.5E-2` (an optional sign, digits with an optional decimal point on either
  side, an optional exponent). A thousands separator (`1,000`), hexadecimal
  (`0x10`), `Inf` and `NaN` are not numbers and are skipped per D1. Rationale:
  the unchanged code recorded the first five forms correctly and without a
  warning; a capture written in a standard spelling of a number is the value
  the user declared (#443 D2). A comma is never read as part of a number:
  depending on the culture it is a thousands separator, a decimal separator,
  or a separator between two values, so no general rule can interpret it.
  Inferring the convention from the analyst's locale is ruled out as well:
  the locale of the server that wrote the log and that of the analyst's
  terminal can differ, and the tool would be assuming where the log came
  from (architect, 2026-09-30). The documentation teaches the pattern that
  catches these forms and names the ones a habitual pattern silently cuts
  short: `--help` and `docs/usage.md` show `/queue size[\s:=]*(\S+)/`, which
  skips the separator and captures the whole value so the tool checks it, and
  state that `(\d+)` reads `1` from `1.5` or `1e3` and that `\D*` before the
  capture drops a minus sign, with no notice. Measured on the twelve-line
  fixture below: the documented pattern records the eight numbers at their
  full value (sum 1049.015, min -5, max 1000) and reports four skipped; the
  earlier example `/queue size\D*(\d+)/` records ten lines with sum 66 and
  no notice (`-5` read as 5, `1.5E-2` as 1, `1,000` as 1, `0x10` as 0).
  This refines D2's example: the capture is the whole value rather than the
  digits.

## Implementation

Branch `638-udm-non-numeric-capture` from `release/0.18.5`.

- **Number shape (D1, D6).** A capture is a number when it holds only the
  characters `0-9 . e E + -` (one `tr` count) and Perl's `looks_like_number()`
  accepts it. The pair accepts exactly
  `[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?` over ASCII digits: compared
  over all 37,448 strings of up to five characters from `019.eE+-`, with no
  difference, and on `Inf`, `NaN`, `0x10`, `1_000`, `1,000`, `0 but true`,
  surrounding whitespace and a non-ASCII digit. The anchored regex matched the
  non-ASCII digit `١` (unflagged `\d` is Unicode) and Perl would have
  recorded it as 0; the pair rejects it. The shape is stated beside
  `$udm_number_re`, which stays the shape the default name and token-key
  patterns extract. The check sits before the delta transform, the unit
  converter and the mask, so a skipped capture touches none of them. The CSV
  column path goes through the same check.
- **Cost of the check.** Measured on the 148 MB single-day access log
  (761,698 lines), old and new `ltl` alternated, five runs each, `-udm
  'b::max:/HTTP\/1.1" \d+ (\d+) /'` (a capture on every line): the anchored
  regex held in a `qr//` object cost +2.3% total (median 12.03 s → 12.31 s),
  about 0.37 µs per capture; in isolation, matching through the `qr//` object
  costs 0.35 µs a value against 0.19 µs for the same pattern written inline
  and 0.055 µs for the `tr` plus `looks_like_number()` pair. With the pair:
  +0.9% (12.26 s, range 12.08 to 12.49, → 12.37 s, range 12.24 to 12.68).
  Without `-udm` (the standard benchmark case): −0.3% (9.14 s → 9.11 s,
  ranges overlapping).
- **Masking.** The counting branch no longer masks an empty capture (an empty
  pattern re-runs whichever regex last matched). On the fixture below, the
  unchanged code's empty pattern reused a regex that does not match the
  message, so the hazard does not show there: the assertion that an empty
  capture masks nothing passes on the unchanged code too, and guards the
  outcome rather than proving the fix.
- **Skip count (D3, D4).** A skipped `/regex/` capture adds the metric's name
  to a per-line list, created only on a skip; past the include/exclude,
  outcome, time-window and numeric filters, the list increments
  `%udm_skipped_lines{<name>}`, a key that exists only once a line of that
  metric was skipped. A CSV column skip is not counted (D3 scope).
- **Notice (D3).** `emit_udm_skipped_capture_notices()`, after the read,
  beside the zero-match notice: `Note: -udm '<spec>': <N> line(s) recorded,
  <N> skipped (<pct>%): the captured text is not a number`. The recorded
  figure is the derived `produced` occurrences (D4); the share is skipped over
  recorded plus skipped. A metric whose every retained line was skipped
  prints both the zero-match notice and this one.
- **`-V udm-specs` (D4, D5).** `produced:` gains `skipped=<N>` only for a
  metric that has one. `source=` is the union of what each file bound, noted
  once per file at its first matched line by `udm_note_sources()`: `line`
  first, then `csv:<column>` or `csv:unbound`, comma-separated, e.g.
  `source=line,csv:v`. Section contract updated in
  `features/user-defined-metrics.md`.
- **Documentation (D2, D6).** The `-udm` regex example in `--help` is
  `ltl -udm "queue::max:/queue size[\s:=]*(\S+)/" app.log`; `docs/usage.md`
  adds it beside the existing regex example. Both `/regex/` rows list the
  accepted forms, the values that are skipped, and the two capture shapes
  that cut a value short without a notice.
- **Tests.** Fixture `tests/fixtures/udm-non-numeric-capture.txt` (a log4j
  application log, seven lines one minute apart, `probe reading v=<value> end`
  with `42`, `12abc`, `abc12`, `abc`, empty, `_:_100`, `7`). Seven scenarios in
  `tests/validate-udm-specs.sh`: `non-numeric-capture`,
  `non-numeric-not-masked`, `all-numeric-capture`, `non-numeric-filtered`,
  `non-numeric-counting`, `non-numeric-csv-column`, `source-mixed-inputs`,
  and `number-forms` on `tests/fixtures/udm-number-forms.txt` (twelve lines,
  the D6 forms and the four non-numbers, behind the separators ` : `, `=`, a
  space or none), which fails on the unchanged code and on the narrower
  `-?\d+(?:\.\d+)?` shape.
  Against the unchanged `ltl` every new assertion fails except the empty-capture
  mask assertions (above) and the two guards for behaviour that was already
  right: no skipped figure or notice on an all-numeric log, and
  `distinct` counting non-numeric text. Those two guards fail when the notice and the
  `skipped=` figure are made unconditional.

## Hand-forward

- #642 (a metric without a `/regex/` records `1e3` as 1 and `1,000` as 1, and
  misses `+5` and `.5`): the default name and token-key patterns still extract
  `$udm_number_re` (`-?\d+(?:\.\d+)?`), so a value written in another D6
  form is cut short or the line is not matched, with no notice. Filed by the
  architect's direction as its own issue, blocked by this one.

## Acceptance criteria

- [x] When a numeric-aggregation metric captures `12abc`, `abc12`, `abc`,
      ` : 100` or an empty value, `produced:` in `-V udm-specs` counts only
      the lines whose capture is a number, and `min`/`sum`/`max` are computed
      from those alone (assertable: fixture of the shapes above; seven lines
      with two numeric captures give `occurrences=2 sum=49 min=7 max=42`).
- [x] That run prints no runtime warning (assertable:
      `tests/lib/runtime-warnings.sh`).
- [x] Under `delta`, a skipped capture between two numeric captures leaves
      the delta equal to their difference (assertable: `produced:`).
- [x] A skipped capture is not masked: the line's message keeps the text
      (assertable: messages section or MESSAGES CSV).
- [x] An empty capture never masks anything in the message (assertable: same).
- [x] A CSV input column holding `n/a` or `5ms` is skipped the same way
      (assertable: the columnar scenario of `tests/validate-udm-specs.sh`).
- [x] When some but not all matched lines of a `/regex/` metric are skipped,
      stderr carries one informational notice for that metric giving the
      recorded count, the skipped count and the skipped percentage; with no
      skip, no such notice (assertable: fixture above; notice line matched on
      stderr, absent on an all-numeric fixture).
- [x] On a run whose every matched line is recorded, `-V udm-specs` carries
      no skipped figure for the metric and stderr carries no skip notice
      (assertable: all-numeric fixture).
- [x] On a run mixing a log file and a CSV file, `-V udm-specs` reports each
      metric's source as what it was actually read from, whichever file is
      read last (assertable: two orderings of the same inputs).
- [x] Lines removed by `-e`/`-i` or the time window count toward neither
      figure (assertable: same fixture with an exclude that removes a skipped
      line).
- [x] The notice carries no ` at <file> line <N>` suffix (assertable:
      `tests/lib/runtime-warnings.sh`).
- [x] Under `distinct`, `abc123` is counted as a value (assertable:
      `produced:` and `tests/validate-udm-counting.sh`).
- [x] Counting aggregations still record non-numeric captures as today
      (assertable: `tests/validate-udm-counting.sh` unchanged and passing).
- [x] A capture written as `42`, `-5`, `+5`, `1.5`, `.5`, `5.`, `1e3` or
      `1.5E-2` is recorded at its full value under a numeric aggregation;
      `1,000`, `0x10`, `Inf` and `NaN` are skipped and reported (D6;
      assertable: scenario `number-forms` of `tests/validate-udm-specs.sh`,
      with the pattern the documentation teaches).
- [x] `--help` examples and `docs/usage.md` carry the whole-value capture
      example, list the accepted forms and name the capture shapes that cut a
      value short, and agree (assertable: `tests/validate-help-content.sh`).
- [x] Hot path: the before/after benchmark on
      `single-day-access-log-standard` shows no regression beyond 1% (+0.2%
      total, −0.5% peak memory on 33d0d25; the `-udm` path +0.9%,
      § Implementation, Cost of the check).

## Harness

`tests/validate-udm-specs.sh` (per-shape `produced:` contract, runtime-warning
check); a committed `.txt` fixture with the capture shapes above.
