# #637 — User-defined metric patterns are tried on continuation lines

Sub-issue of #629 (defects with a user-defined metric using a custom regex and
capture group); umbrella record `features/629-udm-custom-regex-defects.md`.
Owning area: `features/user-defined-metrics.md`.

## Requirement

A run over logs with multi-line entries prints no runtime warning from a
user-defined metric, and a continuation line (a line without a timestamp,
belonging to the entry above it) no longer changes what any metric reports.

## Findings

Measured on release/0.18.5; the capture block is byte-identical on
release/0.19.0 and every result below reproduces there.

- **Why the block runs.** The `## USER DEFINED METRICS CAPTURE` block in
  `read_and_process_logs()` is gated on `if (@udm_configs && defined $message)`,
  not on the line having matched a format. `$message` is a file-scoped record
  variable that an unmatched line neither resets nor overwrites, so it stays
  defined, and the patterns run against the raw line `$_` (#443 D12, the
  pattern matches the whole raw log line).
- **What happens to the value.** `%udm_values` is loop-local, and accumulation
  happens only inside `if( $is_line_match )`; a continuation line takes the
  `note_unmatched_line($in_file)` branch. The value is never recorded or
  attributed to a bucket or message.
- **Side effects that do occur.**
  - The coercion `my $raw_value = $matched_value + 0;` prints a Perl runtime
    warning for a non-numeric capture. On the #629 reproduction (a MethodServer
    log4j log family with 2,971 multi-line DataSource entries carrying
    ` dataQueue size : N` continuation lines), this accounts for all 2,971
    warnings.
  - The delta state `$udm_last_value{$name}` is overwritten. Fixture: a
    timestamped `size10`, a header line and continuation lines, then a
    timestamped `size30`, run with `-bs 1440 -udm "dataQueue::{sum|delta}:/dataQueue size(.+)/"`:

    | Continuation line | `sum` | `delta` sum (correct: 20) |
    |---|---|---|
    | ` dataQueue size : 22440` | `occurrences=2 sum=40`, 1 warning | 30 |
    | ` dataQueue size99` | `occurrences=2 sum=40`, no warning | -69 |

    The numeric case is wrong too, which is why this is separate from #638
    (non-numeric capture recorded as a fabricated value).
  - The mask substitution is applied to the previous line's leftover
    `$message`; harmless, since the next matched line overwrites it.
  - One regex per metric runs on every unmatched line.

## Candidate designs

- **Gate the capture block on the line having matched a format.** Removes the
  warnings and the delta corruption, removes the per-line regex cost on
  unmatched lines, and matches what already happens to the value (never
  recorded).
- **Attribute a continuation line's value to the entry above it.** Makes the
  ` dataQueue size : N` values countable; new behaviour and a multi-line
  record model, beyond a defect fix.
- **Keep the gate, stop continuation lines touching delta state only.**
  Smallest change; keeps the per-line cost and leaves the warnings to #638.

## Decisions

- **D1 — A user-defined metric's patterns are tried only on lines that matched
  a log format.** Continuation lines are ignored by every metric: no capture, no
  coercion, no mask, no delta state. Rationale: their value is never recorded
  today, so nothing reported changes; the warnings and the delta corruption go,
  and so does the per-line regex cost on unmatched lines. Consequence accepted:
  a value that appears only on a continuation line (` dataQueue size : 22440`
  inside a multi-line entry) stays uncounted; attributing it to the entry above
  is a multi-line record feature, not this fix.

## Acceptance criteria

- [ ] When a metric's pattern matches a continuation line whose capture is not
      a number, the run prints no runtime warning (assertable: the
      runtime-warning check of `tests/lib/runtime-warnings.sh` on a fixture
      carrying such a line).
- [ ] When a continuation line carrying a numeric capture sits between two
      timestamped lines, the `delta` sum equals the difference of the two
      timestamped values (assertable: `produced:` in `-V udm-specs`; fixture
      `size10`, continuation ` dataQueue size99`, `size30` gives 20).
- [ ] With continuation lines present, `occurrences`, `sum`, `min` and `max`
      of a `sum` metric equal those of the same fixture with the continuation
      lines removed (assertable: `produced:` in `-V udm-specs`, two runs).
- [ ] Hot path: the before/after benchmark on
      `single-day-access-log-standard` shows no regression beyond 1%.

## Harness

`tests/validate-udm-specs.sh` owns what a spec produced per line shape
(`produced:` in `-V udm-specs`) and already sources the runtime-warning check.
Neither of its fixtures carries continuation lines, so a committed `.txt`
fixture is needed.
