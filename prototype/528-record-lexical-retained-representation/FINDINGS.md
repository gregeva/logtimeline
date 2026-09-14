# 528 — Prototype findings: normalising the retained duration to a number

Prototype for issue #528 (a transform that assigns arithmetic into a shared
record lexical enlarges every duration the raw statistics model retains for the
rest of the run). Built and run to the specification in
`features/528-record-lexical-retained-representation.md` § The prototype.

**The prototype ships no code into `ltl`.** Its output is the measured
recommendation recorded in that document.

## The question

Does normalising the retained duration to a number at each copy site buy enough
memory to be worth a per-retention operation on the hot path?

## What was compared, against what, on what input

**Two arms**, differing by one thing.

| arm | the five retention sites |
|---|---|
| baseline | exactly as `ltl` carries them: each pushes the shared record lexical `$duration` itself |
| normalised | identical, except each site pushes `0 + $duration` — a numeric normalisation of the lexical |

**The five retention sites** are those enumerated in the feature doc's
*§ The retention sites, enumerated*, and every one of the production lines that
defines them is sliced out of `ltl` verbatim by `extract-sites.sh` and asserted
against the prototype's own arm source at startup. A drift in any of them is
fatal, not a warning. At the commit measured:

| site | `ltl` line | the line |
|---|---|---|
| per-bucket durations push | 15278–15279 | `push @{$log_analysis{$bucket}{durations}}, $duration unless $bucket_stats_capture_mode eq 'bin';` |
| per-message durations push | 15119–15120 | `push @{$log_messages{$category}{$log_key}{durations}}, $duration unless $message_stats_capture_mode eq 'bin';` |
| per-message first-sample store | 14975 | `$stats_source->{durations} = [$duration] unless $message_stats_capture_mode eq 'bin';` |
| histogram values push | 15444 | `push @{$histogram_values{duration}}, $duration;` |
| highlighted histogram values push | 15445 | `push @{$histogram_values_hl{duration}}, $duration if $is_highlighted;` |

Sites 4 and 5 are compiled into both arms but fire on no run reported here: the
corpus run draws no histogram, which is the production default. Sites 1, 2 and 3
carry the whole retained population.

**The production call structure is reproduced, not paraphrased.** The record
fields are file-scope lexicals shared by every line, written directly by a
generated closure compiled from a source string — the registry's write-direct
design (D39 of `features/log-format-registry.md`: a single generated scan sub
per scan order, zero per-line sub calls, write-direct into file-scoped record
lexicals). The recognition pattern of each access-family shape is sliced from
its registry spec rather than restated. The registry's startup
extraction-parity gate (gate 2 of `build_format_registry()`) runs before line 1
in both arms. The index block's numeric read
`$fd->{duration_sum} += $duration` runs ahead of every retention site on every
line. The two capture-mode conditions, the two demand gates and the histogram
condition are all present.

**The input**, from `docs/test-logs.md`:

| stage | file | lines |
|---|---|---|
| 5k | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt` | 5,000 |
| 100k | a head of the 05-07 file, cut in the scratchpad | 100,000 |
| 762k | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` | 761,698 |
| correctness only | `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` | 200,000 of 517,684 |

The 22,264-line file is deliberately unused: it is the corrupt specimen whose
concatenated records make duration captures fragments of the following record.

**Twelve timed runs per arm per stage**, pooled from two independent staged
runs (five, then seven), on a quiet machine with nothing else running.
Instrumentation was off in every timed run: a probed third build supplies the
memory figures and its numbers are never mixed with the timed arms', because
loading `Devel::Size` and walking the stores is itself an allocation — the
constraint the issue's sabotage proof established.

## What was observed

### The two structure rows

Exact bytes, probed third build. These figures are bit-identical between the two
independent staged runs.

| stage | row | baseline | normalised | change |
|---|---|---:|---:|---:|
| 5k | `log_analysis` | 363,767 | 163,767 | **−55.0%** |
| 5k | `log_messages` | 512,217 | 312,217 | **−39.0%** |
| 100k | `log_analysis` | 7,308,261 | 3,308,261 | **−54.7%** |
| 100k | `log_messages` | 7,382,695 | 3,382,695 | **−54.2%** |
| 762k | `log_analysis` | 55,742,644 | 25,274,724 | **−54.7%** |
| 762k | `log_messages` | 57,600,664 | 27,132,744 | **−52.9%** |

The mechanism is one number. The retained scalar's body measures **64 bytes** in
the baseline and **24 bytes** in the normalised arm, at every stage — a saving
of 40 bytes on each of the 761,698 retained durations in each of the two stores,
which is 29.1 MB per store and 58.1 MB across both.

The 5k stage's `log_messages` figure is the outlier at −39.0% rather than −53%:
at that scale the store's 218 message keys carry proportionally more per-key
scaffolding than retained durations, so the durations are a smaller share of the
total. From 100k lines upward the two rows move together.

### Against `ltl`'s own rows

The prototype's baseline arm was checked against the figures the tool itself
reports, `MEMORY log_analysis` and `MEMORY log_messages` of `-V benchmark-data`,
on the same 761,698-line corpus, three runs:

| row | `ltl` | prototype baseline | difference |
|---|---:|---:|---:|
| `log_analysis` | 55,831,053 | 55,742,644 | −0.16% |
| `log_messages` | 58,650,211 | 57,600,664 | −1.79% |

So the prototype's per-bucket store is within a sixth of a percent of the
production one and its per-message store within two percent. Projecting the
measured 40-byte-per-duration saving onto the tool's own rows:

| `ltl` row, 762k corpus | as measured today | projected | change |
|---|---:|---:|---:|
| `MEMORY log_analysis` | 55,831,053 | 25,363,133 | **−54.6%** |
| `MEMORY log_messages` | 58,650,211 | 28,182,291 | **−51.9%** |

### Wall clock

Twelve runs per arm per stage, pooled across two independent staged runs.

| stage | arm | median (s) | min | max |
|---|---|---:|---:|---:|
| 5k | baseline | 0.0188 | 0.0187 | 0.0192 |
| 5k | normalised | 0.0185 | 0.0184 | 0.0187 |
| 100k | baseline | 0.3660 | 0.3640 | 0.3677 |
| 100k | normalised | 0.3606 | 0.3576 | 0.3658 |
| 762k | baseline | 2.7919 | 2.7767 | 2.8376 |
| 762k | normalised | 2.7548 | 2.7332 | 2.8269 |

| stage | median change | ranges overlap |
|---|---:|---|
| 5k | **−1.33%** | yes |
| 100k | **−1.49%** | yes |
| 762k | **−1.33%** | yes |

**The normalised arm is not slower. It is faster**, by a median 1.33% on the
761,698-line corpus, and the two arms' ranges overlap at every stage. The
direction reproduced in both independent staged runs, at every stage, without
exception: the per-stage medians were −1.06%, −1.42% and −1.26% in the
five-run set and −1.60%, −1.40% and −1.85% in the seven-run set.

The attribution is that `0 + $duration` is not a net-added operation. It
replaces a copy of a 64-byte three-representation body with the construction of
a 24-byte integer-only one: less memory written per retained value, fewer bytes
touched, and no string buffer allocated for the copy. The saving on the copy is
larger than the cost of the conversion, and the conversion itself is reading an
integer that the lexical already carries, because the index block's
`$fd->{duration_sum} += $duration` has already put it there on the same line.
The measured gain is small and sits inside the overlap of the ranges, so the
defensible statement is that the operation is **free**, not that it is an
optimisation.

### Correctness

Every retained value was dumped in full from both arms and diffed, at full scale
on both specimens.

| specimen | retained-value lines compared | result |
|---|---:|---|
| 761,698-line integer-millisecond corpus | 4,052 | **identical** |
| 200,000 lines of the fractional-millisecond thread-session specimen | 23,990 | **identical** |

The per-arm checksums over the retained populations (`bucket_values_md5`,
`message_values_md5`) match on every stage of every run. **No rendered figure
differs between the arms.**

The fractional specimen is the one *§ The risk to check* named, because a value
retained as `0.005` and rendered from the string could render differently from
one retained as the number, and a trailing zero that survives as text does not
survive as a number. It does not happen on this corpus: the values are dumped
identically.

### The fractional shape costs more in the baseline, and saves more

A finding not anticipated in the plan. On the fractional-millisecond
thread-session specimen the baseline's retained scalar body is **72 bytes**, not
64 — the fractional string's numeric read produces a double, so the retained
copy carries a string, an integer and a double where the integer corpus's
carries only the first two. The normalised arm retains 24 bytes there as well.

| 200,000 lines of the fractional specimen | baseline | normalised | change |
|---|---:|---:|---:|
| retained scalar body | 72 bytes | 24 bytes | −66.7% |
| `log_analysis` | 16,521,389 | 6,921,389 | **−58.1%** |
| `log_messages` | 33,493,803 | 23,893,803 | **−28.7%** |

This matters for the corpus that is not measured here: sixty of the ninety
really-big files are the thread-session shape with fractional milliseconds, so
the saving on that corpus would be larger per retained duration than the one
measured on the integer shape.

## Against the plan's exit criteria

The feature doc's *§ Exit criteria* states the rule.

> Filing the normalisation as its own performance issue is justified if, on the
> 761,698-line corpus, the two structure rows fall by at least ten percent **and**
> the wall-clock median rises by no more than one percent with the ranges of the
> two arms overlapping.

| condition | required | measured | met |
|---|---|---|---|
| `log_analysis` falls | at least 10% | 54.7% | **yes** |
| `log_messages` falls | at least 10% | 52.9% | **yes** |
| wall-clock median rises | at most 1% | it does not rise; it falls 1.33% | **yes** |
| ranges overlap | required | they overlap at every stage | **yes** |
| no rendered figure differs | required | every retained value identical, both specimens | **yes** |

Every condition is met, and the memory condition is met by more than five times
its threshold. This is not the split case: the saving arrived and the cost did
not.

## The ceiling on the alternatives

Three other ways to reach the same saving were considered against what was
measured, and none of them is cheaper.

**Normalising in the transform instead of at the retention sites** does not
work. The retained value must be numeric at the moment the copy is taken, and
the shared lexical is read numerically by the index block on every line before
any site sees it, which re-establishes the string-plus-integer shape whatever
the transform left. The copy is where the representation is fixed.

**Pushing `int($duration)`** buys nothing over `0 + $duration` on this corpus
and would be wrong on the fractional shape, where it would truncate a value the
arms are required to render identically.

**Storing the retained durations in a packed buffer rather than as scalars**
reaches a much lower floor than 24 bytes — but it is a data-model change, it
owns the whole percentile and moments path that reads those arrays, and it is
the subject of #426 (the per-message statistics store is one hash per message;
the as-built heap layout costs 5x on population traversal, on hold), not of a
one-line change at five sites. The 40-byte saving measured here is available
without touching any consumer.

## How to reproduce

```bash
prototype/528-record-lexical-retained-representation/run-stages.sh <output-dir> 5
```

It slices the production lines out of `ltl`, runs both arms at every stage with
the requested number of timed runs each, takes the probed third build's memory
figures separately, and diffs the full retained-value dumps between the arms on
both specimens. `retained-representation.pl --show-sites` prints the sliced
production lines with the `ltl` line they came from; `--dump-loop` prints the
generated read loop for either arm, which is how the two arms' one-line
difference is checked by eye.

## Two traps this prototype hit, recorded so the next one does not

**Instrumentation that reads a value mutates it.** Reading a retained scalar in
string context — which a checksum over the retained population does to every one
of them — asks that scalar to carry a string, and a scalar's body grows on
demand and never shrinks. A size taken after the checksum reports the shape the
checksum imposed, identically in both arms, and the whole effect disappears.
The probe therefore runs before anything else touches the stores, and it sizes
the array element in place: `my $one = $d->[0]` measures the local copy's body,
not the retained one's, and reports the same figure for both arms. This is the
same constraint the sabotage proof recorded, in a second form.

**The assignment shape in the extraction closure is load-bearing.** The
registry's generated block assigns captures as one list assignment from the
match's list-context result, evaluated in boolean context, which leaves
`$duration` a pure string of 48 bytes. Assigning from the numbered capture
variables instead leaves it carrying an extra representation from the start, 88
bytes, which is a baseline `ltl` does not have and which understates the
candidate's saving. The prototype slices the pattern from the registry spec and
reproduces the assignment shape for this reason.
