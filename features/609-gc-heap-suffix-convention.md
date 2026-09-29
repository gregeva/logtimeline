# The Java GC format declares its heap-size suffix convention (Issue #609)

## Status

Planning on branch `609-gc-heap-suffix-convention` off `release/0.19.0`
(base commit be93f58). Unblocked by #608 (one byte-unit ladder with SI and IEC
notation), merged 2026-09-29. D1 and D2 locked, acceptance criteria agreed
2026-09-29 (§ 2, § 3).

Record of the finding that produced this issue:
`features/342-redundant-logic-surfaces-audit-report.md`, finding F1.12 (byte
units on the `-udm` unit slot) and § Review progress, stage 1. Starting state:
`features/608-byte-unit-ladder.md` § 5.9 and D11 (GC heap values do not change
in #608; this issue owns the base-1024 change).

## 1. What the JVM writes (source, 2026-09-29)

The heap figures on a unified-logging GC pause line
(`Pause Young (Normal) (G1 Evacuation Pause) 2433M->66M(49152M) 18.406ms`) are
printed by HotSpot's GC trace-time logger, not by G1 itself, and their unit is
fixed in the code, not chosen per value:

- JDK 11 (`src/hotspot/share/gc/shared/gcTraceTime.inline.hpp`):
  `#define LOG_STOP_HEAP_FORMAT SIZE_FORMAT "M->" SIZE_FORMAT "M(" SIZE_FORMAT "M)"`,
  over `_heap_usage_before / M`, `heap->used() / M`, `heap->capacity() / M`.
- Current mainline (`src/hotspot/share/gc/shared/gcTraceTime.cpp`):
  `out.print(" %zuM->%zuM(%zuM)", used_before_m, used_m, capacity_m);` over the
  same three divisions by `M`.
- `M` is `K*K` with `K = 1024` (`src/hotspot/share/utilities/globalDefinitions.hpp`:
  `const size_t K = 1024; const size_t M = K*K; const size_t G = M*K;`).

What follows for this format:

1. **`M` on the pause line is a mebibyte**, 1,048,576 bytes, in every JDK from
   11 to mainline. Today's reading of it as 10⁶ bytes (§ 5.9 of #608, kept by
   D11 there) understates every heap figure by 4.63 percent.
2. **Only `M` is ever written on this line.** The suffix is a literal in the
   format string; `K`, `G` and `T` do not occur. HotSpot does choose among `B`,
   `K`, `M`, `G` elsewhere (`proper_unit_for_byte_size()`, switching at 100 of
   the next unit down), but not for the pause line's heap transition. `T` is not
   a HotSpot size constant at all.
3. **Each figure is truncated, not rounded**: an integer division by `M`. A
   heap figure understates the true size by up to one mebibyte less a byte, and
   the delta of two figures (`heap_from − heap_to`) is exact to within one
   mebibyte either way.

The HotSpot source is the authority read for these three points.

## 2. Locked decisions

- **D1: the letters are IEC notation, and the whole ladder applies.** HotSpot's
  size constants are powers of 1024 (`K = 1024`, `M = K*K`, `G = M*K`,
  `globalDefinitions.hpp`), so a bare letter on a GC heap figure is an IEC
  prefix: `K` is KiB, `M` is MiB, `G` is GiB and `T` is TiB, as the byte ladder
  holds them. In practice only `M` occurs on a pause line (§ 1), so every GC
  byte value rises 4.86 percent: the format's sample row `2433M->66M` reads
  2,481,979,392 bytes instead of 2,367,000,000, and the G1 test fixture's STATS
  `bytes` total 73,175,924,736 instead of 69,786,000,000 (`68.2 GiB` instead
  of `65 GiB`), confirmed by a run at implementation (§ 6). A user-observable change, so it carries a release-notes
  line. The issue's done-condition becomes: the GC format's spec declares the
  notation its heap figures are written in, and they are read at that notation.
  Locked by the architect 2026-09-29 ("Use what the HotSpot uses"; "This is
  clearly IEC format. You know what the prefixes mean and you know the
  notation. Apply the full ladder.").
- **D2: the existing pattern, no new surface.** The declaration is the spec's
  existing `byte_notation` field, defined in `features/log-format-registry.md`
  as the notation the format's own producer writes byte sizes in; the GC spec
  already declares `iec`. A bare letter is read as the byte-ladder step it
  prefixes, at the notation the entry declares. No new spec field and no table
  of letters: the private map `%gc_heap_suffix_token` beside the transforms is
  deleted, and the one ladder stays the only table of byte units
  (`features/608-byte-unit-ladder.md` D5). Locked by the architect 2026-09-29
  ("this is existing pattern spec which you should be following. The only
  thing that you needed to know is what is the byte notation implied by the
  single letter. Now that you know, the standard ladder applies.").

## 3. Acceptance criteria

Derived from D1 and D2 (§ 2). The G1 test fixture is
`tests/fixtures/gc-g1-categories.txt`: seven lines, five heap transitions, every
figure in `M`. Each criterion runs `-bs 1440 -oe -o` over it unless stated.

- [ ] **AC1. A GC heap figure is read as IEC.** Over the G1 test fixture the
      STATS `bytes` total is 73,175,924,736 and `bytes_nice` reads `68.2 GiB`.
      *Assertable:* scenario `gc-heap-figures-iec` of
      `tests/validate-byte-units.sh`, which replaces the scenario that pinned
      69,786,000,000 and `65 GiB` under `features/608-byte-unit-ladder.md` D11.
      The GC display strings of the notation scenarios move with it
      (`format-declaration`, `mixed-declarations`).
- [ ] **AC2. The format's own samples expect the IEC value.** The GC spec's
      self-validation rows read `2433M->66M` as 2,481,979,392 bytes and
      `512M->128M` as 402,653,184, and the run exits 0 (a self-validation
      mismatch ends every run). *Assertable:* the same scenario's exit-status
      assertion.
- [ ] **AC3. Every prefix on the ladder applies.** A pause line whose figures
      carry `K`, `G` or `T` is read at 1024, 1024³ or 1024⁴ bytes per unit, as
      `M` is at 1024². *Assertable:* a new committed fixture,
      `tests/fixtures/gc-heap-byte-units.txt`, of four G1 pause lines, one
      transition per letter, read by one new scenario of
      `tests/validate-byte-units.sh` (`gc-heap-prefixes`) asserting each line's
      bytes: 2048, 2097152, 2147483648, 2199023255552. A separate
      fixture, so no existing byte-units scenario moves. HotSpot writes only
      `M` on this line (§ 1), so these lines are constructed, which the
      harness's fixture comment says (a `.txt` fixture carries no header of
      its own: every line is read as log input).
- [ ] **AC4. The letters are read at the notation the format declares, not the
      run's output notation.** With `-bn si` the STATS `bytes` total over the G1
      test fixture is still 73,175,924,736, rendered in SI (`73.2 GB`).
      *Assertable:* scenario `gc-heap-figures-iec`.
- [ ] **AC5. The one ladder is the only table.** The GC transform resolves a
      letter through `@byte_unit_ladder` at the entry's declared byte notation;
      no table of letters exists beside the transforms. *Assertable:* the
      source checks of scenario `one-ladder-structure`: `gc-reader-reads-ladder`
      (the reader goes through `byte_prefix_bytes()` and the prefix view of the
      ladder), `no-prefix-letter-table` and
      `gc-transform-reads-declared-notation`. AC4 is the behavioural half.
- [ ] **AC6. No runtime warnings.** No ` at <file> line <N>` on stderr in any
      scenario above. *Assertable:* the harness's runtime-warning check.
- [ ] **AC7. On a real G1 log the only change is the byte values.** Over the
      largest G1 log in the corpus, before against after: line counts and pause
      durations identical, and the bytes total rises by exactly 1.048576 (every
      figure in `M`). *Measured once* and recorded in § 6; the
      corpus is not committed, so no harness reads it.

## 4. Design

- **The prefix view of the ladder.** Beside `byte_unit_canonical()`, one view
  derived from `@byte_unit_ladder`: each step keyed by its prefix letter (the
  first letter of its tokens, `B`, `K`, `M`, `G`, `T`; `kB` and `KiB` agree on
  `K`), and one resolver, `byte_prefix_bytes($letter, $notation)`, returning
  the step's byte count in that notation, or undef for a letter no step
  carries. No letters are written anywhere; a step added to the ladder is a
  prefix the GC figures accept.
- **The GC read.** `gc_heap_size_bytes($figure, $notation)` splits the figure
  into its number and letter and multiplies by `byte_prefix_bytes()`. The
  private map `%gc_heap_suffix_token` is deleted. A figure it cannot read
  returns 0, as today (unchanged behaviour; HotSpot writes none, § 1).
- **The notation reaches the transform at compile time.** The `gc_heap_delta`
  snippet names the notation as a placeholder that the transform loop of the
  scan-sub codegen replaces with the entry's declared `byte_notation`, the way
  the mask pattern's `KEYS` placeholder is filled from the spec. A spec that
  lists the transform without declaring `byte_notation` fails the registry
  build. The per-line cost is the same two lookups and a multiply as today.
- **The spec's sample rows** expect the IEC values: `2433M->66M` 2481979392,
  `512M->128M` 402653184 (AC2).
- **Records.** `features/log-format-registry.md`: the `byte_notation` field
  entry gains how the format's bare size letters are read, and the ladder
  entry names the prefix view and resolver in place of the GC map.
  `features/608-byte-unit-ladder.md` § 5.9: its hand-forward is marked
  delivered here. `releases/v0.19.0.md`: one bullet in the fixes section.

## 5. Delivery

One drop on this branch: the code, the spec's sample rows, the harness
scenarios and fixture of § 3, and the records of § 4, in one commit and a push.
Before it, `$version_number` is stamped `0.19.0-609` and the before benchmark
(`single-day-access-log-standard`, label `609-before`) is captured on the base
commit be93f58. Then AC7 is measured and recorded here, the version restored,
and the completion gate run: the full harness suite and the after benchmark.

## 6. Implementation record

### Drop 1 (2026-09-29)

Built as § 4 describes. `byte_prefix_bytes()` and `%byte_unit_by_prefix` sit
beside `byte_unit_canonical()`; `gc_heap_size_bytes()` takes the notation as
its second argument; the `gc_heap_delta` snippet carries a `BYTE_NOTATION`
placeholder that the transform loop of `format_entry_block_src()` fills from
the entry; `%gc_heap_suffix_token` is deleted; the GC spec's sample rows expect
2481979392 and 402653184.

**Acceptance criteria.** `tests/validate-byte-units.sh`: 48 passed, 0 failed.
Each new or changed assertion was shown to fail first, on a sabotaged `ltl`:

| Sabotage | Assertions that failed |
|---|---|
| The GC spec declares `si` | `gc-heap-figures-iec`: all four (the self-validation rows end the run; the total; the rendering; the `-bn si` total). `gc-heap-prefixes`: its one |
| The transform reads the run's `-bn` value in place of the entry's notation | `gc-heap-figures-iec`: the `-bn si` total only. `one-ladder-structure`: `gc-transform-reads-declared-notation` |
| A private letter-to-token table beside the ladder | `one-ladder-structure`: `no-prefix-letter-table` and `byte-tokens-only-in-ladder` |

**AC7, the largest G1 log in the corpus** (781,118 lines, 83 MB), before on
be93f58 and after on this drop, both `-ni -bs 1440 -oe -o -V`: 781,118 lines
read in both; the STATS CSV has 54 rows in both, and the only columns that
differ are `bytes`, `bytes_max`, `bytes_mean` and `bytes_nice`. On every row the
byte value after is exactly 1.048576 times the value before. No stderr on
either run.


### Completion gate (2026-09-29, on d3511a7)

`$version_number` restored to `0.19.0` first (d3511a7).

**Full harness suite:** all 44 `tests/validate-*.sh` exit 0, each summary
showing assertions run (`validate-csv-output.sh` then `validate-statistics.sh`
under `CI=1`, then the rest). `validate-statistics.sh`: 22 of 22 scenarios, with
its one registered known failure reported as XFAIL. No ` at <file> line <N>`
in any capture.

**Benchmark** (`single-day-access-log-standard`, 761,698 lines, before on the
unchanged tool of be93f58, after on d3511a7, one run each): total 9.1 s to
8.9 s, `rss_peak` 99.7 MB to 99.2 MB, line counts identical. One memory row
read as a regression: `format_scan_subs` +64 KB (+5.7%). That row is the RSS
growth across scan-sub compilation, which moves in whole pages. Measured again
three times each on the same log with `-V format-registry`,
`scan_subs_rss_bytes`: before median 1,212,416 (range 1,196,032 to 1,228,800),
after median 1,146,880 (range 1,146,880 to 1,261,568). The ranges overlap and
the after median is lower: noise, not a cost of the change. Both benchmark TSVs
deleted after the comparison.
