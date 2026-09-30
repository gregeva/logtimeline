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
  warning, and is not masked in the message. Clean numeric captures, counting
  aggregations and the built-in name and token-key patterns are unchanged.
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

## Acceptance criteria

- [ ] When a numeric-aggregation metric captures `12abc`, `abc12`, `abc`,
      ` : 100` or an empty value, `produced:` in `-V udm-specs` counts only
      the lines whose capture is a number, and `min`/`sum`/`max` are computed
      from those alone (assertable: fixture of the shapes above; seven lines
      with two numeric captures give `occurrences=2 sum=49 min=7 max=42`).
- [ ] That run prints no runtime warning (assertable:
      `tests/lib/runtime-warnings.sh`).
- [ ] Under `delta`, a skipped capture between two numeric captures leaves
      the delta equal to their difference (assertable: `produced:`).
- [ ] A skipped capture is not masked: the line's message keeps the text
      (assertable: messages section or MESSAGES CSV).
- [ ] An empty capture never masks anything in the message (assertable: same).
- [ ] A CSV input column holding `n/a` or `5ms` is skipped the same way
      (assertable: the columnar scenario of `tests/validate-udm-specs.sh`).
- [ ] Counting aggregations still record non-numeric captures as today
      (assertable: `tests/validate-udm-counting.sh` unchanged and passing).
- [ ] `--help` examples and `docs/usage.md` carry the narrowed-capture example
      and agree (assertable: `tests/validate-help-content.sh`).
- [ ] Hot path: the before/after benchmark on
      `single-day-access-log-standard` shows no regression beyond 1%.

## Harness

`tests/validate-udm-specs.sh` (per-shape `produced:` contract, runtime-warning
check); a committed `.txt` fixture with the capture shapes above.
