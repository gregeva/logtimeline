# The Java GC format declares its heap-size suffix convention (Issue #609)

## Status

Planning on branch `609-gc-heap-suffix-convention` off `release/0.19.0`
(base commit be93f58). Unblocked by #608 (one byte-unit ladder with SI and IEC
notation), merged 2026-09-29. D1 locked 2026-09-29 (§ 2).

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

- **D1: the suffixes mean what HotSpot's size constants mean.** `K` is 1,024
  bytes, `M` is 1,048,576 bytes (`K*K`) and `G` is 1,073,741,824 bytes (`M*K`),
  the constants in HotSpot's `globalDefinitions.hpp`: the ladder's `KiB`, `MiB`
  and `GiB`. `T` is not a HotSpot size constant and is not declared. In practice
  only `M` occurs on a pause line (§ 1), so every GC byte value rises 4.86
  percent: the format's sample row `2433M->66M` reads 2,481,979,392 bytes
  instead of 2,367,000,000, and the G1 test fixture's STATS `bytes` total
  73,175,924,736 instead of 69,786,000,000 (`68 GiB` instead of `65 GiB`),
  figures computed from the fixture's values and confirmed by a run at
  implementation. A user-observable change, so it carries a release-notes line.
  The issue's done-condition becomes: the GC format's spec declares what its
  heap-size suffixes mean, and heap figures are read at that meaning. Locked by
  the architect 2026-09-29 ("Use what the HotSpot uses").
