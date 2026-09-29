# The Java GC format declares its heap-size suffix convention (Issue #609)

## Status

Planning on branch `609-gc-heap-suffix-convention` off `release/0.19.0`
(base commit be93f58). Unblocked by #608 (one byte-unit ladder with SI and IEC
notation), merged 2026-09-29. D1 and D2 locked 2026-09-29 (§ 2).

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
  `bytes` total 73,175,924,736 instead of 69,786,000,000 (`68 GiB` instead of
  `65 GiB`), figures computed from the fixture's values and confirmed by a run
  at implementation. A user-observable change, so it carries a release-notes
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
      STATS `bytes` total is 73,175,924,736 and `bytes_nice` reads `68 GiB`.
      *Assertable:* the GC scenario of `tests/validate-byte-units.sh`, whose
      present expectations (69,786,000,000, `65 GiB`, contract
      `features/608-byte-unit-ladder.md` D11) are rewritten to D1 of this doc.
- [ ] **AC2. The format's own samples expect the IEC value.** The GC spec's
      self-validation rows read `2433M->66M` as 2,481,979,392 bytes and
      `512M->128M` as 402,653,184, and the run exits 0 (a self-validation
      mismatch ends every run). *Assertable:* the same scenario's exit-status
      assertion.
- [ ] **AC3. Every prefix on the ladder applies.** A pause line whose figures
      carry `K`, `G` or `T` is read at 1024, 1024³ or 1024⁴ bytes per unit, as
      `M` is at 1024². *Assertable:* a new committed fixture of four pause lines,
      one transition per letter, and one scenario asserting each line's bytes.
      HotSpot writes only `M` on this line (§ 1), so these lines are
      constructed, and the fixture's header says so.
- [ ] **AC4. The letters are read at the notation the format declares, not the
      run's output notation.** With `-bn si` the STATS `bytes` total over the G1
      test fixture is still 73,175,924,736, rendered in SI (`73 GB`).
      *Assertable:* one scenario in the same harness.
- [ ] **AC5. The one ladder is the only table.** The GC transform resolves a
      letter through `@byte_unit_ladder` at the entry's declared byte notation;
      no table of letters exists beside the transforms. *Unassertable by a
      harness* (AC4 is the behavioural half): verified at review of the diff.
- [ ] **AC6. No runtime warnings.** No ` at <file> line <N>` on stderr in any
      scenario above. *Assertable:* the harness's runtime-warning check.
- [ ] **AC7. On a real G1 log the only change is the byte values.** Over the
      largest G1 log in the corpus, before against after: line counts and pause
      durations identical, and the bytes total rises by exactly 1.048576 (every
      figure in `M`). *Measured once* and recorded in this doc's implementation record; the
      corpus is not committed, so no harness reads it.
