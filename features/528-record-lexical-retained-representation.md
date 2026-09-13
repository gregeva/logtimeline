# 528 — What a transform may leave in a shared record lexical

Issue #528 (a transform that assigns arithmetic into a shared record lexical
enlarges every duration the raw statistics model retains for the rest of the
run).

This document owns the contract on what a format transform may assign into a
shared record lexical, the regression assertion that detects a breach, and the
plan for the prototype that costs the one candidate change measured to be worth
considering.

**No production code ships under this issue.** The tool's behaviour, its output
and its memory use are unchanged by the work described here. What ships is a
written contract, one harness assertion, and a prototype whose output is a
measured recommendation for the architect to decide on.

## Status

**The contract and the regression assertion are built, proven able to fail, and
committed.** `tests/validate-statistics-demand.sh` carries the retained-duration
scenario; the committed tree reads 32,329 bytes against a 33,000-byte ceiling,
and a build with the string coercion removed from the `duration_from_unit_token`
transform reads 35,801 and fails the harness. The contract is stated here under
*The contract* and beside F11a in `features/log-format-registry.md`. The harness
alone reports 97 passed, 0 failed against 95 before the change; the full suite is
the completion gate's to run.

**The prototype is not built.** It is the separate later stage described under
*The prototype*, and it waits on #544 (the profiling workflow cannot run on the
development machine). Nothing in the candidate it measures is implemented, and
no decision about retained-duration normalisation has been taken.

## The motivating consumer

Two consumers pay for what a transform leaves behind, and neither of them is the
transform's own format.

**The raw statistics model's retained durations.** In its default configuration
`ltl` keeps every observed duration as a scalar in an array, so that the exact
percentiles can be computed at the end of the run. On a single-day access log
that is hundreds of thousands of scalars in `%log_analysis` (per bucket) and
again in `%log_messages` (per message key), plus `%histogram_values` when a
histogram is drawn. Each of those scalars is a copy of one shared lexical,
`$duration`, and it inherits that lexical's internal shape at the moment of the
copy. Eight unused bytes in the source lexical is eight unused bytes multiplied
by the retained population: six megabytes on a 762,000-line access log, measured
under #444 (access-log format family and user surface).

**The completion-gate benchmark.** Every issue whose diff touches an executable
line of `ltl` owes a before/after benchmark on this machine, and a peak-memory
metric worse by more than five percent is stop-and-investigate. Under #444 that
benchmark moved by 7.6 and 8.7 percent on two runs with every count identical,
because one format's transform had changed the shape of a lexical every other
format shares. A benchmark that can be moved from a place the diff appears not
to touch costs a full investigation each time it happens, and nothing in the
tree stops it happening again.

## The requirement, as restated

The issue's "Done when" has two clauses. Only the first survives contact with
measurement.

**First clause, kept and made precise.** No transform may leave a shared record
lexical holding a value Perl represents as a double, and a harness assertion
detects it if one does. The code already holds this invariant; nothing asserts
it.

**Second clause, withdrawn.** "The memory cost of retained durations does not
depend on ... which unit conversion a run performed" is not achievable and is
not wanted. It is not achievable because the representation of a retained copy
is determined by the representation of the source lexical at the copy, and a
unit conversion is an assignment into that source lexical. It is not wanted
because the dependence runs in the favourable direction: a run that converts
retains *less*, not more. Measured on the 5,000-line Tomcat access slice
(`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt`),
three runs each, `%log_analysis` / `%log_messages`: no conversion 361 / 572 KiB;
`-du ms` 283 / 494 KiB; `-du us` and `-du ns` both 322 / 541 KiB. Requiring
independence from the conversion would mean giving up an eleven to twenty-two
percent saving that runs get today, to buy nothing.

The withdrawal of the second clause is recorded as D3 below, with the
consequence that "conversion is neutral for memory" is explicitly not a property
this tool has or aims for.

## Corrections to the issue body

These come from the settling measurements, which instrumented the running tool
rather than modelling it. Each correction names what was measured, on what.

1. **"The same exposure remains for `-du`" is wrong, and inverted.** A run that
   passes `-du` retains *less* than a run that does not, by eleven to
   twenty-two percent on the raw stores, on the 5,000-line access slice, three
   runs each. The reason is not that a numeric assignment shrinks the source
   lexical, which it cannot do. It is that assigning a number invalidates the
   source lexical's string flag, so the retained copy allocates no string
   buffer: forty-eight bytes per retained duration under `-du ms`,
   fifty-six under `-du us` and `-du ns`, against a sixty-four byte baseline
   with no conversion.

2. **"A transform that assigns a floating-point result" is correct, and it is
   narrower than the issue's title suggests.** The title says "assigns
   arithmetic". Integer arithmetic costs nothing, because every duration is read
   numerically before it reaches any retention site: `$fd->{duration_sum} +=
   $duration` in `read_and_process_logs()`'s per-file index block runs for every
   line with a defined duration, ahead of the filters and every push. That read
   alone makes the integer-carrying body the floor on every run, so an
   integer-valued assignment into the lexical can never raise it. The
   `gc_heap_delta` transform, which assigns `convert_bytes( $heap_from ) -
   convert_bytes( $heap_to )` into `$bytes` and runs through the same startup
   gate, costs nothing. Only a value Perl represents as a double raises the body.

3. **"The transform now stores its result as a string, which keeps the
   lexical's body small" is correct.** The `'' .` in `duration_from_unit_token`
   is load-bearing and measured to work. The comment block above it in
   `%format_transform_code` needs no correction, and neither does
   `features/444-access-log-format-family-and-user-surface.md` §
   Implementation findings.

4. **The "Done when" second clause is withdrawn**, per the requirement section
   above.

5. **Every other reference in the issue body is accurate.** The three linked
   documents exist and are quoted correctly; #444, #524 and #426 carry the
   titles the issue gives them.

## The mechanism, for a reader who does not know Perl internals

Five facts in sequence produce the defect. None of them is exotic; the surprise
is only in how far apart in the code they sit.

**One set of lexicals is shared by every format for the whole run.** The
registry declares `my ( $bytes, $duration );` once at file scope, beside the
other record fields. Under D39 of `features/log-format-registry.md` (a single
generated scan sub per scan order: zero per-line sub calls, write-direct into
file-scoped record lexicals) every format's extraction code writes straight into
those same variables rather than returning a record. This is what makes the hot
loop fast, and it is also what makes one format's transform able to affect every
other format's output.

**A Perl scalar's internal storage grows and never shrinks.** A Perl variable is
a small header pointing at a body, and the body is enlarged on demand to hold
whichever of the representations the variable has been asked to carry: a string,
an integer, a floating-point number, or some combination. Enlarging it is a
one-way operation for the life of the variable. Assigning a new value later, or
assigning `undef`, changes what the variable *holds*; it does not give back the
slot the body acquired. So `format_record_reset()`'s `( $bytes, $duration ) = (
undef, undef );` restores the values between runs and between validation gates,
and cannot restore the shape.

**A copy inherits the source's shape.** When a retained duration is pushed into
an array, Perl allocates a new scalar for the copy and gives it a body able to
carry what the source carries. A source carrying a string and an integer
produces a copy with room for both. A source that has at some point carried a
floating-point number produces a copy with room for the double as well, whether
or not the value in it needs one. This is why an event at startup is still being
paid for on the last line of the last file.

**A startup gate runs every format's transforms before line 1.** `build_format_registry()`
validates the registry on every run of the tool. Its gate 2, the extraction-parity
loop, calls each entry's real extraction closure over that entry's declared
sample lines, and an extraction closure includes that entry's transforms. So a
transform belonging to a format the run will never encounter still executes,
against the shared lexicals, before the first real line is read. The
`access_common_duration_bracketed` entry declares samples whose durations end in
`[0.005s]` and `[0.012s]`, so its unit transform fires on every run of `ltl`
whatever the input. (The gate that does *not* execute extraction closures is
gate 5's startup half, which classifies each sample through the interpreted
classifier `format_classify_interpreted()` and touches no extraction.)

**The remedy is a string coercion, and the reason the floor is not lower.** The
committed transform is `$duration = '' . convert_duration_to_ms($duration,
$duration_unit_token) ...`. Concatenating with the empty string turns the
conversion's numeric result into a string before it is assigned, so the lexical
is asked to carry a string, which it already can. The floor this leaves is not
the smallest possible one: the numeric read in the index block described in
correction 2 above means the lexical always carries a string *and* an integer by
the time any retention site sees it, sixty-four bytes per retained duration.
Below that floor lies only the number-only shape a conversion produces, which is
the subject of the prototype in this document rather than of the contract.

Measured inside the running tool at the per-bucket retention push in
`read_and_process_logs()`, on the 5,000-line Tomcat access slice (which binds no
bracketed entry) and on the Codebeamer bracketed specimen
(`logs/Codebeamber/codebeamer_access_log.2025-10-29.txt`), three repetitions each:

| transform form | retained scalar body | `%log_analysis` | `%log_messages` |
|---|---|---|---|
| as committed, `'' . convert_...` | string plus integer, 64 bytes | 361 KiB | 572 KiB |
| reverted to the bare conversion | string plus double, 72 bytes | 400 KiB | 611 to 612 KiB |

## Decisions

### D1 — This issue delivers a written contract and a regression assertion, and changes nothing about how retained durations are stored

Architect-locked. The defect instance is fixed; the defect class is live,
because the fix is protected only by a comment and the full harness suite passed
green while the broken form was in the tree. The deliverable is the gap that is
actually open: a working fix that is invisible and unasserted. Folding a
representation change into a bug fix would broaden the issue past the reported
case and would owe a benchmark this issue does not otherwise owe.

### D2 — A prototype is part of this issue, and it measures the normalisation candidate

Architect-locked. The candidate is: normalise the retained duration to a number
at each copy site, so the copy carries no string buffer, which is the effect
`-du` already produces as a side effect. It is measured for time cost and memory
saving on a large example case, so that the decision whether to pursue it is
made on measured gain against measured cost rather than on the attractiveness of
the number. Its exit is a measured recommendation (medians with ranges) recorded
in this document; the architect decides from it. **The prototype does not ship
code**, and nothing in it is promoted into `ltl` under this issue.

### D3 — "Done when" is restated as the invariant the code holds today

No transform may leave a shared record lexical holding a value Perl represents
as a double, and a harness assertion detects it if one does.

Reason: it is exactly what the committed code satisfies, so the assertion is
written against a known-good tree and can be sabotage-proven against the known-bad
one. It is narrow enough not to forbid `gc_heap_delta`'s integer arithmetic,
which is measured to cost nothing. And it is the only form of the requirement
that is directly observable through a surface that already exists.

The issue's second clause, independence from unit conversion, is withdrawn: it
cannot be met by any candidate design, because a conversion is by definition an
assignment into the source lexical, and it is not wanted, because the dependence
today makes converting runs cheaper rather than more expensive. Adopting it
would make the measured eleven to twenty-two percent saving a defect.

### D4 — The contract governs every shared record lexical as a class; the assertion covers `$duration` only

The shared record lexicals declared at file scope beside `@format_record_fields`
are `$timestamp_str`, `$category_bucket`, `$object`, `$instance`, `$user`,
`$session`, `$platform`, `$thread`, `$message`, `$bytes`, `$duration`,
`$status_code` and `$metrics_observed`. The contract applies to all of them.
The two that carry numeric values a transform is likely to compute, and that
have retention sites, are `$duration` and `$bytes`.

Reason for stating it as a class: the rule is about what the shared-lexical
design permits, not about one variable, and it costs nothing extra to say so.
A future transform that divides into `$bytes` would cost exactly what the
floating-point form of `duration_from_unit_token` cost.

Reason for asserting on `$duration` only: `$bytes` today costs nothing to
breach, because the only transform writing arithmetic into it writes an integer,
and its single retention site `push @{$histogram_values{bytes}}, $bytes` is
active only when a histogram is drawn. A second assertion for a cost that is
currently zero is not earned. Should a transform ever assign a division into
`$bytes`, the assertion shape in this document extends to it by changing the
fixture and the row read.

### D5 — The assertion reads the exact `MEMORY` rows of `-V benchmark-data`, not the rounded `-mem` summary rows

The `-mem` summary surface prints `log_analysis` and `log_messages` rounded to
whole KiB. On a fixture small enough to commit, the rounding boundary is close
enough to the signal that consecutive runs of the same build differ by a
displayed KiB. The same figures reach `-V benchmark-data` as exact byte counts
on `MEMORY` rows, from the same `named_structure_sizes()` producer, and those
are bit-stable. Reading the exact rows is the same measurement without the
rounding, on a section that already has a stability contract and existing
harness consumers.

### D6 — The record is this document; `features/log-format-registry.md` gains one line beside F11

The constraint is transform-side and the registry document owns the transforms,
D39's write-direct record lexicals and F11's rule that per-compile validation
must disturb nothing. But the cost lands in the statistics model's retention
sites, which that document does not own, and this issue also carries an
assertion and a prototype plan. Splitting those across the registry document
would bury them. So the registry document gains one line beside F11 stating
which startup gate executes extraction closures against the record lexicals
(gate 2, the extraction-parity loop) and which does not (gate 5's startup half,
the interpreted classification path through `format_classify_interpreted()`),
plus a pointer here. Two successive investigations guessed wrong about those
gates in opposite directions, which is the reason the line is worth its space.

### D7 — Two findings are forwarded to the architect rather than filed under this issue

Neither belongs to the defect and folding either in would broaden the issue.

- `tests/validate-format-detection.sh` has no top-level argument parsing, so an
  unknown flag such as `--scenario family-bracketed-unit` is silently accepted
  and all 255 assertions run. A selector that is accepted and ignored is worse
  than one that is rejected, and the working practice of iterating a harness
  with a single-test selector assumes such a selector exists.
- The measured per-duration retained sizes, for whoever picks up #426
  (per-message statistics store is one hash per message; the as-built heap
  layout costs 5x on population traversal, on hold): sixty-four bytes on a
  default raw-mode run, forty-eight under `-du ms`, fifty-six under `-du us` or
  `-du ns`. It is a range rather than a point figure, and it moves if the
  candidate in D2 is ever pursued. No code dependency exists between #426 and
  this issue, so no blocking edge is recorded.

## The contract

Stated as it will appear beside F11 in `features/log-format-registry.md` and as
the assertion's `contract` field points at it.

> **A format transform may not leave a shared record lexical holding a value
> Perl represents as a double.**
>
> The record lexicals are declared once at file scope and shared by every
> registry entry for the whole run (D39: a single generated scan sub, write-direct
> into file-scoped record lexicals). A Perl scalar's body grows on demand and
> never shrinks, and every copy taken from a lexical inherits a body able to
> carry what that lexical carries. So a floating-point value assigned into
> `$duration` or `$bytes` by any entry's transform is paid for by every value
> the statistics model retains from that lexical afterwards, for every format,
> on every file of the run, whether or not the value needs it.
>
> The exposure is not limited to the formats a run encounters. Gate 2 of
> `build_format_registry()`, the extraction-parity loop, executes every entry's
> real extraction closure over that entry's declared samples before the first
> line of input is read, and a transform is part of an extraction closure. One
> entry's sample is enough.
>
> A transform that computes a value therefore assigns it in one of two forms:
> as a string, by concatenating the empty string, the form
> `duration_from_unit_token` uses; or as an integer, which costs nothing because
> every duration is already read numerically by `$fd->{duration_sum} +=
> $duration` in `read_and_process_logs()`'s per-file index block, ahead of every
> retention site. Assigning the raw result of a division or of any computation
> that can produce a fractional value is a defect.
>
> `format_record_reset()` restores the values and cannot restore the shape.

## The assertion

### Where it lives

`tests/validate-statistics-demand.sh`, as a new scenario.

The naming rule in `tests/HARNESS-DESIGN.md` is that a harness file name tracks
the `-V` section it validates. The rows this assertion reads are `MEMORY` rows
of `-V benchmark-data`, and `benchmark-data` has no harness of its own: it is
read by six existing harnesses, each asserting the rows belonging to the feature
it validates (`tests/validate-format-registry.sh` asserts `MEMORY
format_scan_subs`, for the same reason). The rule's intent, that a reader can
tell from the filesystem what a harness validates, is served by putting the
assertion with the feature it is about rather than with the transport it reads.

The feature it is about is what the raw statistics model retains, which is what
`validate-statistics-demand.sh` already validates: per-store resolved demand,
per-store moment source, and the block-boundary populations. A retained-duration
representation assertion sits with the retained-duration demand assertions. It
also already uses the access-log fixture family and already reads
`-V benchmark-data`.

The addition to `tests/HARNESS-DESIGN.md` is one paragraph under **Naming
rules**, stating the case the rule did not previously cover:

> **A section with no owning harness is asserted by the harness owning the
> feature the rows describe.** `benchmark-data` is a transport: its rows carry
> figures produced elsewhere, and each row belongs to the feature that produces
> it. A harness asserting one of its rows is named for that feature, not for
> `benchmark-data`. `validate-format-registry.sh` asserts `MEMORY
> format_scan_subs`; `validate-statistics-demand.sh` asserts the `MEMORY
> log_analysis` row that carries the retained-duration representation. The file
> name still tracks a section for every harness that owns one.

### The invocation

```
./ltl --disable-progress -mem -bs 1440 -oe -V benchmark-data -n 1 \
    tests/fixtures/tomcat-access-duration-spread.txt
```

Shaped to the assertion that reads it, per the invocation-coherence rule: `-mem`
because the structure rows are gated on it; `-bs 1440` to fold the fixture's
14.5 hour span into a single bucket, which removes the per-bucket hash overhead
that is unrelated to the signal and is the only source of run-to-run variance
observed; `-oe` to switch off the empty-bucket fill; `-n 1` because no rendered
row is read; `-V benchmark-data` to narrow the output to the transport.

### The fixture

`tests/fixtures/tomcat-access-duration-spread.txt`, a committed, tracked
fixture: 434 lines, twelve synthetic endpoints, TEST-NET addresses, already
listed in `docs/test-logs.md` and already read by
`tests/validate-duration-display.sh`. It is pinned in the sense that matters
here: it is regenerated only by an explicit script run, and the assertion's
threshold is stated with the line count it was derived from so that a
regeneration that changed the count is visible as a failure rather than as
drift.

Its 434 durations are enough. The signal is eight bytes per retained duration in
`%log_analysis`, so a 434-line fixture separates the two forms by 3,472 bytes,
which is an order of magnitude above the observed variance.

### The fields read and the threshold

One row: `MEMORY\tlog_analysis\t<bytes>`.

Measured on this machine, five runs of each build under the invocation above:

| build | `MEMORY log_analysis` | `MEMORY log_messages` |
|---|---|---|
| as committed, string form | 32,329 bytes on all five runs | 49,875 on four runs, 48,851 on one |
| transform reverted to the bare conversion | 35,801 bytes on all five runs | 53,387 on all five |

`log_analysis` is bit-identical across five runs of each build under this
invocation. `log_messages` is not: it moves by one hash-bucket resize step
(1,024 bytes) between runs of the same build, which is why the assertion reads
`log_analysis` and not both.

**Threshold: the row must be at most 33,000 bytes. Repetition count: one run.**

A ceiling rather than a range, because the invariant is one-sided: the defect
can only make the number larger. 33,000 sits 671 bytes above the committed
figure and 2,801 bytes below the breached one, so a hash resize or a fixture
edit of a few lines does not trip it and a breach cannot hide under it. One run
is sufficient because the figure is bit-identical across five; the tolerance
carries the margin instead of repetition, which keeps the harness's runtime
where it was.

### The assertion's three documentation fields

```
asserts     'The retained per-bucket durations carry no floating-point slot: a
             transform that assigns a double into a shared record lexical
             enlarges every duration retained afterwards, and the per-bucket
             statistics store grows by 8 bytes per retained duration when one does'
produced_by 'named_structure_sizes() in ltl, reached through
             measure_memory_structures(); the retained values come from the
             per-bucket durations push in read_and_process_logs()'
contract    'features/528-record-lexical-retained-representation.md § The contract,
             and features/log-format-registry.md F11: a transform may not leave a
             shared record lexical holding a value Perl represents as a double'
```

### Sabotage proof

Required before the assertion is called done, per the rule that a new assertion
is proven able to fail.

`duration_from_unit_token` is not a sub. It is a key in `%format_transform_code`
whose value is a `q{}` string of Perl source, named in the
`access_common_duration_bracketed` entry's `transforms` list and compiled into
the generated scan sub. The sabotage is therefore an edit to that one string,
not to a function body.

**The precondition stated when this section was written no longer holds.** The
settling captures do hold two builds, one with the coercion and one without, but
neither is identical to the committed tree: both carry an extra instrumentation
line at the per-bucket retention push in `read_and_process_logs()` that calls
`Devel::Size::size()` under an environment-variable guard. `diff` against the
committed `ltl` reports two differing lines for the no-coercion build, not one.
A build that allocates a probe array and loads two modules is not a build whose
memory figure proves anything about the committed one, so the proof was produced
against a build reproduced for it rather than against the settling capture.

**What was done instead.** A copy of the committed `ltl` was taken into the
scratchpad and the two characters `'' .` deleted from the
`duration_from_unit_token` value, giving a build whose `diff` against the
committed tree is exactly one line, the transform string itself. It was never
committed and never placed in the working tree except for the duration of the
harness run below, after which the tree was restored and verified to differ from
the branch point only by `$version_number`.

**The run.** The assertion's invocation, against
`tests/fixtures/tomcat-access-duration-spread.txt`, 434 lines, five repetitions
of each build on this machine:

| build | `MEMORY log_analysis` | `MEMORY log_messages` |
|---|---|---|
| committed tree | 32,329 bytes on all five runs | 49,875 bytes on all five runs |
| one-line reproduction without the `'' .` coercion | 35,801 bytes on all five runs | 53,387 on four runs, 52,363 on one |

Both `log_analysis` figures reproduce the ones recorded under *The fields read
and the threshold* exactly, and the separation is 3,472 bytes, which is eight
bytes for each of the fixture's 434 retained durations. `log_messages` again
moves by one 1,024-byte hash-bucket resize step between runs of the same build,
which is why the assertion reads `log_analysis` alone.

**The harness result.** Running `tests/validate-statistics-demand.sh` with the
no-coercion build in place: 96 passed, 1 failed, exit 1. The failing assertion
reports the measured value, the ceiling, and all three documentation fields:

```
  FAIL  scenario-13-retained-duration-representation
        command:     [[ '35801' -le 33000 ]]
        label:       MEMORY log_analysis is 35801 bytes, at or below the 33000 ceiling
        asserts:     The retained per-bucket durations carry no floating-point slot: ...
        produced_by: named_structure_sizes() in ltl, reached through measure_memory_structures(); ...
        contract:    features/528-record-lexical-retained-representation.md section The contract, ...
```

Against the committed tree the same harness reports 97 passed, 0 failed, exit 0,
with the scenario's assertion reading 32,329 bytes.

**Finding, for whoever next needs a known-bad build of this defect.** Reproducing
it costs one `cp` and one two-character deletion at the
`duration_from_unit_token` entry of `%format_transform_code`; that is cheaper and
more trustworthy than locating a capture from an earlier session and checking
what else it carries. A capture kept for a memory measurement is only a valid
comparison build if it differs from the tree by the change under test alone, and
an instrumented capture does not.

## Acceptance criteria

Triaged per `docs/test-driven-development.md` before implementation.

### Assertable

- [x] **Assertable.** A run of `./ltl --disable-progress -mem -bs 1440 -oe -V
      benchmark-data -n 1 tests/fixtures/tomcat-access-duration-spread.txt`
      reports a `MEMORY log_analysis` row of at most 33,000 bytes.
      *Method:* the new scenario in `tests/validate-statistics-demand.sh`.
      *Met:* the row reads 32,329 bytes, identical on five consecutive runs of
      the committed tree; the scenario passes.
- [x] **Assertable.** The same run against a build whose
      `duration_from_unit_token` transform assigns the conversion result without
      the string coercion reports a row above the ceiling, and the assertion
      fails, naming the contract.
      *Method:* the sabotage run described above, recorded in this document with
      both figures.
      *Met:* 35,801 bytes against the 33,000 ceiling; the harness reports 96
      passed, 1 failed, exit 1. The build was reproduced for the proof rather
      than taken from the settling captures, for the reason recorded under
      *Sabotage proof*.
- [x] **Assertable.** The assertion's failure output names the invariant, the
      producing function in `ltl`, and this document, so a reader can tell a
      regression from a stale assertion without opening another file.
      *Method:* inspection of the FAIL output produced by the sabotage run.
      *Met:* the FAIL block carries the measured value against the ceiling,
      `asserts` naming the eight-bytes-per-retained-duration invariant,
      `produced_by` naming `named_structure_sizes()` and the per-bucket
      durations push in `read_and_process_logs()`, and `contract` naming this
      document and the registry document's F11a line.
- [x] **Assertable.** `features/log-format-registry.md` states, beside F11,
      which startup gate executes extraction closures against the record
      lexicals and which does not, and points here.
      *Method:* inspection of the committed diff.
      *Met:* the F11a line, committed with the specification, names gate 2 (the
      extraction-parity loop) as the gate that executes transforms against the
      record lexicals and gate 5's startup half (interpreted classification
      through `format_classify_interpreted()`) as the gate that does not.
- [ ] **Assertable.** The full harness suite exits 0 with assertions reported as
      having run, and the new scenario's count appears in
      `validate-statistics-demand.sh`'s summary.
      *Method:* the completion gate.
      *Pending:* the gate stage runs the suite. The owning harness on its own
      reports 97 passed, 0 failed, exit 0, against 95 before this change: the
      new scenario contributes two assertions, the retained-duration ceiling and
      the fixture line-count guard that the ceiling's derivation depends on.

### Unassertable

- [ ] **Unassertable, recorded as a known gap.** That *no* transform in
      `%format_transform_code` assigns a double into a record lexical. The
      assertion observes the aggregate effect of every transform gate 2
      executes, on one fixture, through one lexical. A transform belonging to an
      entry whose samples happen not to exercise the offending branch would not
      be caught, and neither would a breach of `$bytes`.
      *Reason:* there is no surface that reports a lexical's internal shape, and
      adding one would mean a new `-V` figure with a section contract and every
      consumer updated, for a class whose cost today is measured at zero outside
      `$duration`. *What is done instead:* the contract is written where a
      transform author reads it, and the one lexical with a measured cost is
      asserted. D4 records the decision and the extension path.

### Unknown

None. Both the invariant and its verification method were settled by measurement
before this specification was written, which is why no verification-method
prototype is in scope. The prototype below is a cost prototype, not a
verification-method one.

## The prototype

Planned here, not built under this specification. It is mandatory under
`prototype/README.md` triggers (b) a new per-line hot-path cost and (c) a cost
profile of execution frequency times per-execution cost, both of which fire on
the candidate.

### The question

Does normalising the retained duration to a number at each copy site buy enough
memory to be worth a per-retention operation on the hot path?

The candidate makes every raw-mode run retain what a `-du` run already retains:
forty-eight bytes per retained duration instead of sixty-four, an eleven to
twenty-two percent reduction on `%log_analysis` and `%log_messages` measured on
the 5,000-line slice. The cost is one operation per retained duration, executed
once per line per active retention site.

### The corpus

`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt`
(Tomcat 9, 148 MB, 761,698 lines, durations in milliseconds, bytes, from
`docs/test-logs.md`). It is the 762,000-line single-day access log on which the
#444 measurement was made, so the prototype's figures are comparable with the
six megabytes and the 7.6 to 8.7 percent already recorded. It binds
`access_common_duration`, reads durations and bytes, and drives the raw
statistics model by default.

The staged scale is the 5,000-line slice
(`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt`),
then the 22,264-line file is deliberately not used (it is the corrupt specimen),
then a 100,000-line head of the 05-07 file cut in the scratchpad, then the whole
761,698 lines. Four stages, per `prototype/README.md`'s 1k to millions ladder
adapted to the corpus that exists.

### The arms

**Baseline.** The retention sites exactly as committed, extracted from `ltl`
rather than rewritten. Per `prototype/README.md`, the baseline arm reproduces
the production call structure verbatim: the same shared file-scope lexical
written by a generated closure, the same numeric read in the index block ahead
of the pushes, the same per-site conditions, no convenience wrapper. Constants
(the retention-site conditions, the demand booleans, the unit ladder) are sliced
out of `ltl` by a script following the pattern of
`prototype/459-order-independence/extract-subs.sh`; any value that must be
restated names its source symbol in a comment beside it.

**Normalised.** Identical, except that each retention site pushes a numeric
normalisation of the lexical rather than the lexical.

**A constraint the sabotage proof established, which applies to both arms.** A
build used as a memory comparand is valid only if it differs from its comparand
by the change under test alone. Instrumentation that reads a scalar's size is
itself an allocation: the settling captures of this issue carry a probe at the
per-bucket retention push that pushes onto its own array and loads
`Devel::Size` and `B`, and a figure taken from such a build cannot be compared
with one taken from a clean build. Each arm is therefore measured with its
instrumentation off, through the `-V benchmark-data` rows the tool already
emits, and any probing arm is kept as a third build whose figures are never
compared against the other two.

### The retention sites, enumerated

Found by grepping for pushes and stores of `$duration` in `read_and_process_logs()`.
All five are in scope for the normalised arm:

1. The per-bucket durations push, `push @{$log_analysis{$bucket}{durations}},
   $duration unless $bucket_stats_capture_mode eq 'bin'`.
2. The per-message durations push, `push
   @{$log_messages{$category}{$log_key}{durations}}, $duration unless
   $message_stats_capture_mode eq 'bin'`.
3. The per-message first-sample store, `$stats_source->{durations} = [$duration]
   unless $message_stats_capture_mode eq 'bin'`, on the branch that creates a
   message key's statistics source.
4. The histogram values push, `push @{$histogram_values{duration}}, $duration`.
5. The highlighted histogram values push, `push
   @{$histogram_values_hl{duration}}, $duration if $is_highlighted`.

Sites 1 and 2 dominate the retained population. Sites 4 and 5 are active only
when a histogram is drawn, and site 3 fires once per message key. The other
appearances of `$duration` in the loop (`$stats_source->{total_duration}`,
`total_duration_num`, `sum_of_squares`, the per-file index accumulators, the
per-bucket totals) are numeric accumulations rather than retained copies and are
not touched.

The `$bytes` retention site, `push @{$histogram_values{bytes}}, $bytes`, is out
of scope: the candidate is about the duration string buffer, and `$bytes` is
already numeric on the paths that reach that push.

### The measurements

On a quiet machine, with no other agent running `ltl`.

- **Peak memory.** The `MAXIMUM MEMORY USED` figure, and the `MEMORY rss_peak`
  row of `-V benchmark-data`.
- **The two structure rows.** `MEMORY log_analysis` and `MEMORY log_messages`,
  exact bytes, both arms, every stage.
- **Wall clock.** At least five runs per arm per stage, reported as medians with
  the full range. The per-stage `TIMING` rows of `-V benchmark-data` are
  captured alongside, so that a change concentrated in the read phase can be
  distinguished from one spread across the run.
- **Correctness.** Every rendered figure and every count identical between the
  arms at every stage, checked by diffing full output.

### Exit criteria

The prototype exits with a measured recommendation, medians with ranges,
recorded in this document. It does not exit with code.

**Filing the normalisation as its own performance issue is justified if**, on
the 761,698-line corpus, the two structure rows fall by at least ten percent
*and* the wall-clock median rises by no more than one percent with the ranges of
the two arms overlapping. Ten percent is the bottom of the range already
measured for `-du`, so a smaller saving would mean the candidate does not
deliver what the side effect delivers. One percent is well inside the five
percent the completion gate treats as stop-and-investigate, and the overlap
condition is there because a per-line operation whose cost is visible above run
noise on a 762,000-line file will be visible on the eight and a half gigabyte
corpus too.

**It is recorded as not worth pursuing if** the wall-clock median rises by more
than one percent with non-overlapping ranges, or if the memory saving is below
ten percent, or if any rendered figure differs between the arms.

**If the two conditions split** (the saving arrives and the cost is real, or the
cost is free and the saving is small), the recommendation states both numbers
and the disposition question goes to the architect with the trade named rather
than resolved.

### The risk to check

A retained value that becomes numeric where it was a string can change a
rendered spelling at a formatting boundary: a value that was retained as `0.005`
and rendered from the string is retained as the number and may render as `0.005`
or as `5e-03` depending on the path that formats it, and a trailing zero that
survived as text does not survive as a number. The check is the regression
goldens: the full-output diff described under measurements above, run at every
stage, on a corpus carrying fractional durations as well as integer ones. The
thread-session shape
(`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt`,
fractional milliseconds to three places) is added as a correctness-only arm for
that reason, without timing, since fractional durations are where a spelling
change would show.

## Completion gate

Scope per `docs/process/workflow.md` § 3, applied to the diff as specified.

**Full harness suite: required.** The diff touches `tests/validate-statistics-demand.sh`,
which is a `tests/validate-*.sh` file, and the table's row for that path reads
"required (what passing means changed)".

**Before/after benchmark: skipped, and the skip recorded in the completion
comment.** No executable line of `ltl` changes. The rest of the diff is
`features/528-record-lexical-retained-representation.md` (new),
`features/log-format-registry.md` (one line beside F11) and
`tests/HARNESS-DESIGN.md` (one paragraph under Naming rules), all of which fall
in the exempt row.

**The condition that changes this.** The scope test is about what could change
behaviour, not about how the change feels, and the "exempt path plus required
path in the same commit" row makes the stricter answer win. If the assertion
turns out to need any change to `ltl` (a figure that is not emitted, a row that
is gated differently than measured here, a section contract that has to move),
then the benchmark becomes required as well, and the `-V` change rules in
`tests/HARNESS-DESIGN.md` apply in full: every consumer updated in the same
commit, each affected harness executed and seen to assert, the reserved-names
list updated. As specified, no such change is expected: the row the assertion
reads exists today, is produced by `named_structure_sizes()`, is gated on `-mem`
as every structure row is, and was read from a live run of the committed tree.

**As built, the condition did not fire.** The assertion reads
`MEMORY log_analysis` from the committed tool exactly as specified: no `-V`
section, key or gating changed, and no executable line of `ltl` was edited. The
only edit to `ltl` on this branch is `$version_number`, stamped to the branch
form at the start of the work and restored to `0.18.1` by the gate stage before
it runs, so the commit the gate measures carries no `ltl` change at all. The
benchmark skip therefore stands as specified, and the full harness suite is
required because `tests/validate-statistics-demand.sh` changed.

## Release note

None. Nothing in this issue is user-observable: no output changes, no option
changes, no behaviour changes, no memory figure changes. A release-notes bullet
would describe work on the project rather than a change to the tool.

## Ordering against the other next-up issues

No blocking relationship in either direction, and no `blocked_by` edge is
recorded.

- **#472** (the highlight bin-counter sub-stores are absent from the `-V`
  telemetry, so a highlighted run under-reports its own partitions and memory)
  was checked specifically, because it is the nearest neighbour to the
  assertion's surface. It does not change any row the assertion reads. Its
  subject is the `-V histogram-bin-counters` consumer names and the three
  highlighted bin-counter stores `%heatmap_counters_hl`,
  `%histogram_counters_hl` and `%bucket_stats_counters_hl`. The assertion reads
  `MEMORY log_analysis`, which is the raw per-bucket statistics store, a
  different structure produced by a different site, and its invocation carries
  no highlight and runs the raw bucket data model, under which the highlighted
  counter stores hold nothing. Either disposition #472 takes leaves the row
  untouched. The two can be worked in either order.
- **#475** (severity levels a supported format can emit are missing from the
  log-level array) and **#476** (log levels declared per format in the registry,
  with unregistered levels reported at end of run) both edit entries in
  `format_registry_specs()`. Neither touches the transforms or the record
  lexicals. Landing this issue's contract before or alongside them is preferable
  so the rule is already in the document their registry work is read against,
  but it is a preference and not a dependency.
- **#478** (highlight bookkeeping is evaluated on the hot path when no highlight
  is active and when the metric is absent) is the only other next-up issue in
  the same hot path in `read_and_process_logs()`. As specified this issue
  changes nothing there, so there is no conflict. Should the prototype's
  candidate ever be filed and worked, that work and #478 touch adjacent lines
  and should not be in flight at once.
- **#426** (per-message statistics store is one hash per message; the as-built
  heap layout costs 5x on population traversal, on hold) and **#354** (`-mdm
  bin` uses more message-stats memory than `-mdm raw` for high-cardinality logs)
  are downstream of the prototype's candidate, not of this issue. The measured
  per-duration sizes in D7 are for whoever picks #426 up.
- **#527** (the statistics harness leaves an aggregate export in the repository
  root that the export harness's relative-path scenario then reads) is unrelated
  to the defect, and shares only the property of being harness hygiene.
- **#482** (two `-udm` specs with the same name and aggregation but different
  transforms collapse into one column) is unrelated.
