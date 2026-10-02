# Carrying a timestamp's nanoseconds exactly: cost prototype findings

Owning record: `features/525-timestamp-precision-option.md` § 6.5 and § 9
(drop 5, D4). Script: `525-nanosecond-cost.pl` in this directory; run as
`perl 525-nanosecond-cost.pl ltl 5` from the repository root (`0` rounds runs
the validation only). Measured 2026-10-02 on the development machine against
`ltl` at 2e1e98f.

## Question

How to carry a timestamp's sub-second part exactly, to nine digits, from the
parse to the surfaces that render it (the run summary heading's bounds, the
aggregate export's observation, the run index's first and last timestamps),
and at what per-line cost: when nanosecond is asked for, and when it is not.

## Research

| Constant | Measured |
|---|---|
| Perl integer width | 64 bits (`ivsize` 8): `1769421601 * 1_000_000_000 + 999999999` stays an exact integer (IOK, not NOK) |
| Floating epoch resolution at present-day epochs | 238 ns: `.123456789` is held as `.123456717` |
| Lines whose nine digits the floating epoch reproduces | 8 077 of 1 000 000 (3-digit fractions), 4 216 of 1 000 000 (9-digit) |

Rounding to the nearest double is monotonic: it never reverses the order of
two instants, it can only make them equal. So the floating comparisons the
read loop already makes order every pair of lines correctly except a tie, and
a tie includes `.999999999` beside the next second's `.000000000`, which round
to the same double.

## Arms

All arms run the same timestamp strings through the same per-line code:
the variable-length fraction block of `format_entry_block_src()` and the read
loop's epoch and bound updates of `read_and_process_logs()`, sliced verbatim
out of `ltl` at run time, the record variables file-scope lexicals closed over
by a generated sub, as in production. The layout parse is the same stand-in
in every arm.

| Arm | What it adds to today's code |
|---|---|
| A | nothing: the baseline |
| B | integer nanoseconds from the digit string beside the integer seconds; the six bounds (file row first/last, selection row first/last, heading min/max) kept exact as (seconds, nanoseconds) pairs |
| C | one 64-bit integer of nanoseconds; the six bounds kept as that integer |
| D | the six floating comparisons kept; the line's digit string kept; the exact value taken when a bound moves, compared on a tie |
| G | D's bound updates and today's behind a run flag, chosen at each of the three update sites; flag off |
| H0 | today's six statements unchanged, plus two flag tests per line (before the filters, after them); flag off |
| H1 | H with the flag on: a bound whose value equals this line's epoch (it just moved here, or it ties) takes this line's exact (seconds, digits) if they are better |

## Correctness

| Check | B | C | D | H1 |
|---|---|---|---|---|
| Every line's nine digits, 1 000 000 lines of 3-digit and of 9-digit fractions | exact | exact | (bounds only) | (bounds only) |
| The six bounds, 1 000 000 lines of each | exact | exact | exact | exact |
| Six crafted ties: lines nanoseconds apart out of order, `.999999999` beside the next second's `.000000000` | exact | exact | exact | exact |

No surface renders an individual line's timestamp; the surfaces that render
at nanosecond precision are the six bounds and the bucket labels, whose keys
are integers at the scale `-bs` gives (D14). D and H therefore keep the digits
only where a bound needs them.

## Cost

ns per line over the baseline, medians of five interleaved rounds after a
warm-up pass, ranges in brackets; each row's own baseline is shown.

| Fraction | Lines | A (ns/line) | G, not asking | H0, not asking | D, asking | H1, asking | C, asking | B, asking |
|---|---|---|---|---|---|---|---|---|
| 3-digit | 1 000 | 980 [976–996] | +83 | +28 | +193 | +279 | | |
| 3-digit | 10 000 | 999 [977–1580] | +68 | +11 | +195 | +269 | | |
| 3-digit | 100 000 | 989 [986–1012] | +69 | +21 | +199 | +316 | | |
| 3-digit | 1 000 000 | 1058 [985–1541] | +107 | −32 | +131 | +348 | | |
| 9-digit | 1 000 | 1154 [1081–1251] | +27 | −32 | +150 | +219 | | |
| 9-digit | 10 000 | 1103 [1086–1147] | +46 | −4 | +186 | +254 | | |
| 9-digit | 100 000 | 1073 [1066–1085] | +74 | +23 | +183 | +293 | | |
| 9-digit | 1 000 000 | 1076 [1073–1079] | +72 | +27 | +195 | +344 | | |

B and C, from the run before G and H were added (five rounds, same machine):
B +560 to +656, C +473 to +637 ns/line.

The tool's whole per-line cost, for scale (step 3d, interleaved medians):
6.04 µs on a generated variable-length-fraction log, 6.67 µs on the corpus
application log, 9.5 µs on the corpus access log.

## Reading

- **Not asking** is what every run pays. H0's difference from A is within the
  rounds' own spread (−32 to +28 ns, under 0.5 % of the tool's per-line cost);
  G's is a steady +27 to +107 ns (up to 1.8 % of the 6.04 µs per line), because each of its three
  sites wraps statements the baseline runs bare.
- **Asking** is paid only by a run that asks for nanosecond over a log whose
  timestamps carry more than six digits. H1 costs +219 to +348 ns/line, about
  4 to 6 % of the tool's per-line time; D is cheaper on (+131 to +199) but
  needs G's always-paid branching; C and B cost two to three times H1.
- Scale is flat from 1 000 to 1 000 000 lines in every arm.

## As built

Locked as D23 and built as H. End to end against the build before it,
alternating, `parse/read_files` medians: not asking, −0.2 % on the corpus
application log (nine rounds; an A/A control moved −1.0 %), +0.5 % on a
generated variable-length log, +0.3 % on the corpus access log; asking
(`-tp ns`) on a generated nine-digit log, +8.3 %. The record is
`features/525-timestamp-precision-option.md` § 10, drop 5. The script slices
the six-digit strip of the build it measured; the strip now reads nine digits.

## Recommendation

H: today's floating bound updates unchanged, the digit string kept by the
variable-length block only when the run asks for nanosecond (a compile
option, as for the capture gate), and two flag tests per line taking the
exact value when a bound moves or ties. It meets both exit conditions of
§ 9: nine digits reproduced exactly at every bound, crafted ties included;
the arm not asked for indistinguishable from the baseline.
