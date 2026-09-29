# One byte-unit ladder with SI and IEC notation (Issue #608)

## Status

Specification agreed with the architect 2026-09-28 on branch
`608-byte-unit-ladder` off `release/0.19.0` (base commit 58f8d94). Implementation
in progress on the same branch, synced to `release/0.19.0` at 99fd43a: drop 1
(the byte ladder and the unit slot) and drop 2 (help rows) delivered; drops 3
and 4 not started. § 11
records what each drop built and measured.

This issue carries stage 2 of the review of the redundant-logic audit (unit
ladders): the `-udm` byte-unit bug found in stage 1, and the three stage 2
findings added to it (bytes near a unit boundary on display, unit lists written
by hand in help rows, two private decimals tables). Record of the findings:
`features/342-redundant-logic-surfaces-audit-report.md` § Item 1 and § Item 2,
and § Review progress, stages 1 and 2.

Ordering:

- It blocks #605 (numeric, byte and duration inputs accept a value with a unit),
  whose unit parse reads this ladder, and #609 (the Java GC format declares its
  own heap-size suffix convention), which declares that convention beside the
  byte notation field this issue adds to the format spec (D12) and owns the GC
  value change this issue does not make (D11).
- #617 (one width-to-format rule) and #616 (one gated derivation of means and
  totals) land after this issue. All three re-bless regression goldens, and each
  later one captures on the tree the earlier one left. Both edges are recorded
  as native blocked-by relationships in the delivery stage (§ 9).

---

## 1. The motivating consumer

Three readers depend on bytes meaning one thing.

1. **An analyst who writes `-udm 'resp:KB:max'`** expects the same number every
   run. Today the same command reports the metric in 1000-byte units on some runs
   and 1024-byte units on others, a 2.4 percent swing per kilo step, and the CSV
   column is named `resp_KB_max` on some runs and `resp_kB_max` on others. A
   comparison of two runs, or of a run with last week's CSV, is wrong without
   any sign that it is.
2. **Anyone reading a bytes column, heatmap scale or histogram axis** expects the
   unit printed to be the unit meant. Today 1000, 1023 and 1024 bytes all print
   `1 KiB`, and 1,000,000 and 1,048,575 bytes both print `1 MiB`, so the label is
   wrong by up to 2.4 percent per step at the boundary, and the notation (IEC)
   is not the one the tool accepts `kB` and `MB` in.
3. **The next author of a byte-valued input** (the threshold options of #605,
   values with a unit, first; then the GC format's own suffix convention of
   #609) needs one table to call. Today there are three private byte tables and
   a fourth of plain-number multipliers, none of which agrees with another, and
   whichever the author copies becomes a fifth.

The consumer is served when one byte ladder at file scope, in the shape the
time-unit ladder already has, is the only definition of byte units; the option
slot, the GC transform, the display formatter and the help rows all read it; and
the notation the output uses is chosen once per run and says so.

---

## 2. Requirement

The architect's terms, from the issue body, its comment of 2026-09-27, and the
stage 1 and stage 2 decisions of the audit review, organised but not
reinterpreted. The architect's answers of 2026-09-28 to the questions the draft
could not settle are § 4, D11 to D20.

### Defect

The unit given on the `-udm` unit slot does not resolve to one meaning. The same
command gives a value that differs between two runs, and the unit vocabulary the
option accepts contradicts the SI and IEC notation the tool uses elsewhere.

### Wanted (stage 1)

- The unit spelling is taken from the command line as given, and its lookup is
  case-insensitive: `kb`, `kB`, `KB` and `Kb` are one unit.
- Unit meanings follow SI and IEC notation: `kB`, `MB`, `GB`, `TB` are powers of
  1000; `KiB`, `MiB`, `GiB`, `TiB` are powers of 1024. `kB` and `KB` as two units
  with two meanings is wrong and is not kept.
- A user-defined metric assumes no base; the base comes from the unit given.
- The `-udm` help row and `features/user-defined-metrics.md` say what the option
  does.
- The fix is the one byte ladder, not a separate fix the ladder would replace
  (issue comment, 2026-09-27).

### Added at stage 2 (2026-09-27)

- **Bytes near a unit boundary on display.** The display climb is the ladder's
  multiplier compared against the value, as the count formatter climbs; the
  formatter keeps no table of its own.
- **Output byte notation.** One notation per run, SI (`kB`, `MB`, `GB`) or IEC
  (`KiB`, `MiB`, `GiB`), chosen by a run option, defaulted by the log format's
  declaration in its spec, SI when no format declares one. The ladder carries
  both notations; the formatter renders in the run's notation. The option has
  short and long forms, a `--help` row and a `docs/usage.md` row. The Java GC
  format declares IEC, in the same place #609 (the GC format's own heap-suffix
  convention) declares its input convention.
- **Unit lists in help rows.** A help row that names a unit vocabulary
  interpolates the ladder's list, never a literal, for time units and byte units
  alike, with a help-content harness scenario asserting it; the threshold rows of
  #605 (inputs with a unit) then follow the rule.
- **Decimals per unit.** The default is the same on every surface, the source's
  resolution, and it is a field of the ladder step derived from the step's
  length, covering every token. Higher precision for follow-up analysis is the
  existing `-cp, --csv-precision` knob, not a different default; no sub keeps a
  decimals table of its own.
- The format data model's per-format defaults (#386, format data model: default
  analysis precision per format) do not yet define a format's units, conversion
  or base unit; that is added there, and this issue's format-declared default
  reads it. The placement of the byte notation field is changed by D12 (the
  field is added in this issue).

### Done when

The same `-udm` command gives the same value on every run, the unit resolves as
the notation says, 1000 bytes renders as `1 kB` under SI, and the output notation
follows the option or the format's declared default.

---

## 3. Corrections to the issue body and the audit record

Verified on `ltl` at 58f8d94 by `grep -F` inside each named sub and by captured
runs (scratch captures, one file per run). Each names what was looked for and
what was found.

1. **The nondeterminism reproduces, and reaches the CSV column name.** A
   three-line access-log fixture whose request lines carry `?elapsed=5&v=1`
   (then 7/2, 9/3), `-udm 'v:<unit>:max' -V udm-specs -bs 1440 -oe`, eight fresh
   runs per spelling: `KB` read 1024 on six runs and 1000 on two; `kB`, `kb`
   and `Kb` read 1024 on three and 1000 on five. `KiB` and `kib` read 1024 every
   run; `MB` read 1,000,000 every run. With `-o`, eight runs of `-udm 'v:KB:max'`
   named the STATS column `v_KB_max` five times and `v_kB_max` three times: the
   CSV header is nondeterministic as well as the value, which the issue body
   does not say.
2. **`B` and `b` flip too.** `-udm 'v:B:max'` reported `unit=B(bytes)` on three
   runs and `unit=b(bytes)` on five. Both multiply by one, so the value is
   stable; the reported spelling and the column name are not. The fold
   `parse_udm_configs` :: `my %byte_unit_canonical = map { lc($_) => $_ } keys %byte_units;`
   collapses both pairs.
3. **`K` on the unit slot is a plain number, as the issue says; it is checked
   before any fold.** `parse_udm_configs` :: `if (exists $si_units{$unit}) {`
   runs case-sensitively first, so `k` and `K` resolve to `unit=K(number)`,
   ×1000, on every run. This is not a byte unit and this issue does not change
   it (D3: a user-defined metric assumes no base).
4. **The Java GC heap delta is not base 1024 today.** The body of #609 (the GC
   format's heap-suffix convention) says the GC format's `K`, `M`, `G` agree with
   the JVM's base-1024 convention "by a private table entry". Only `K` does.
   `convert_bytes` maps `'K' => 1024` but `'M' => 1000**2`, `'G' => 1000**3`,
   `'T' => 1000**4`, and the heap sizes the GC log writes are almost always in
   `M`. The registry's own self-validation row for the sample line
   `2433M->66M(49152M)` expects `2367000000` bytes, 2367 × 10⁶; the JVM's meaning
   is 2367 × 1,048,576 = 2,481,979,392. The committed G1 GC fixture (five heap
   transitions, all in `M`) sums to 69,786,000,000 bytes and renders `65 GiB` in
   the STATS `bytes_nice` cell: the value is parsed in SI and displayed in IEC.
   D11 (GC heap values do not change in this issue) settles the order: § 5.9.
5. **The byte converter has two callers, not three.** The audit's inventory
   lists `emit_index_readback_verbose` :: `convert_bytes(` as a caller. That sub
   contains no call; the line is the `gc_heap_delta` entry of the file-scope
   `%format_transform_code` table, which follows that sub in the file. The
   callers are `parse_udm_configs` (the unit slot's converter closure) and the
   `gc_heap_delta` transform, which is spliced into the GC entry's generated
   extraction code.
6. **The byte converter builds its table on every call.** `convert_bytes`
   declares `my %units = (` inside the sub, so every converted `-udm` value and
   every GC line builds a sixteen-entry hash (the GC transform does it twice per
   line). The ladder removes the cost; see § 8.
7. **The display climb collapses a step at every boundary, not only the first.**
   A nine-line access-log fixture with response sizes 999, 1000, 1023, 1024,
   999,999, 1,000,000, 1,048,575, 1,048,576 and 1,500,000 bytes, one per minute,
   `-o -bs 1`: the STATS `bytes_nice` cells read `999 B`, `1 KiB`, `1 KiB`,
   `1 KiB`, `976.6 KiB`, `1 MiB`, `1 MiB`, `1 MiB`, `1.4 MiB`. The rule is
   `format_bytes` :: `if( length( $bytes_int ) >= length( $units{$u} ) ) {`,
   with its `TO DO: 1000kB should convert to MB` comment beside the commented-out
   value comparison.
8. **The per-metric formatter field is never read.** `parse_udm_configs` stores
   `formatter => $formatter` on each metric's config; no code reads it. Every
   display surface picks the formatter from the config's `unit_type`
   (`print_bar_graph` :: `} elsif ($unit_type eq 'bytes') {` and
   `format_heatmap_value` :: `$ut eq 'bytes' ? format_bytes($value, 'B') :`).
   The field goes with the ladder rather than being kept in step with it.
9. **Every caller of the byte formatter passes `'B'`.** Its unit argument and its
   private six-entry table exist to scale a value that always arrives in bytes.
   The callers are in `print_bar_graph`, `format_heatmap_value`,
   `print_summary_table`, `print_message_summary` and `write_aggregate_export`.
10. **The `-ru` help row is not the same literal as the other three.** The
    audit's help-row finding says the `-du`, `-ru`, `-bs` and `-udm` rows carry
    the same literal. The `-du` and `-udm` rows write `ns, us, ms, s, m, h, d, w,
    month, year`; the `-bs` row writes it inside `(units: …; m is always the
    minute, a month is 30 days and a year 365)`; the `-ru` row writes it in two
    parts with glosses (`s (second), m (minute, default), h (hour), d (day), or
    any other unit of the same ladder (ns, us, ms, w, month, year)`).
    Interpolating the ladder's list therefore rewords the `-ru` row (§ 5.6).
11. **Two records state rules the code does not follow.**
    `features/user-defined-metrics.md` § Unit Types says every byte unit is base
    1024 and matching is case-insensitive with `kb = KB`; the code maps `kB`,
    `MB`, `GB`, `TB` to powers of 1000 and `KB` to 1024 and folds them
    nondeterministically. Its § Design Decisions says CSV column names are
    lowercase; the header carries the unit's case (`v_KiB_max`; a time unit
    appears as its canonical token, `-udm w:minutes:max` gives `w_m_max`).
12. **The two decimals tables are where the audit placed them, and the resolved
    duration unit comes from `-du` only.** `%duration_display_decimals` sits at
    file scope before `format_duration`; `%decimals_by_unit` sits inside
    `adapt_to_command_line_options`, where `$duration_unit_resolved` is set to
    the `-du` value or `ms`. No format spec declares a duration unit other than
    `ms` (a unit written beside the value is converted per line), so "the
    source's resolution" is the `-du` unit or the millisecond on every run
    today.
13. **No harness exercises a byte unit on the unit slot.** No scenario in
    `validate-udm-specs.sh`, `validate-udm-counting.sh`, `validate-csv-output.sh`
    or `validate-doc-examples.sh` passes `B`, `kB`, `KB`, `KiB` or `MB` to
    `-udm`. The defect had nothing to fail.

---

## 4. Locked decisions

Each restates a decision the architect has locked; the source is named. Nothing
else in this document is a decision.

### Locked 2026-09-27 (issue body and the audit review, stages 1 and 2)

- **D1 — The spelling is looked up case-insensitively.** The unit spelling is
  taken from the command line as given, and its lookup is case-insensitive:
  `kb`, `kB`, `KB` and `Kb` are one unit. Locked by the architect 2026-09-27,
  stage 1 of the audit review of #342 (redundant-logic surfaces) (issue body,
  *Wanted*).
- **D2 — SI and IEC meanings.** `kB`, `MB`, `GB`, `TB` are powers of 1000;
  `KiB`, `MiB`, `GiB`, `TiB` are powers of 1024. `kB` and `KB` as two units with
  two meanings is not kept. Locked 2026-09-27, stage 1.
- **D3 — No assumed base.** A user-defined metric assumes no base; the base
  comes from the unit given. Locked 2026-09-27, stage 1.
- **D4 — The records say what the option does.** The `-udm` help row and
  `features/user-defined-metrics.md` state the unit vocabulary and its meanings.
  Locked 2026-09-27, stage 1.
- **D5 — The fix is the one byte ladder.** The byte vocabulary is corrected by
  building one ladder, in the shape of the time-unit ladder of
  `features/524-bucket-size-unit.md` D1 (one ladder at file scope, read by every
  surface of the vocabulary; no sub keeps a table of its own), not by a separate
  fix the ladder would replace. Locked 2026-09-27, stage 1 re-evaluation (this
  issue carried as stage 2's issue; issue comment of the same day).
- **D6 — Value-based display climb.** The display climb is the ladder's
  multiplier compared against the value, as the count formatter climbs; the
  formatter keeps no table of its own. Locked 2026-09-27, stage 2 (the finding
  on bytes near a unit boundary).
- **D7 — One output notation per run.** One notation per run, SI (`kB`, `MB`,
  `GB`) or IEC (`KiB`, `MiB`, `GiB`), chosen by a run option, defaulted by the
  log format's declaration in its spec, SI when no format declares one. The
  ladder carries both notations; the formatter renders in the run's notation.
  The option has its short and long forms, `--help` row and `docs/usage.md` row.
  The Java GC format declares IEC, in the same place #609 (the GC format's own
  heap-suffix convention) declares its input convention. Locked by the architect
  2026-09-27, stage 2 (issue body).
- **D8 — Help rows interpolate the ladder.** A help row that names a unit
  vocabulary interpolates the ladder's list, never a literal, for time units and
  byte units alike, with a help-content harness scenario asserting it; the
  threshold rows of #605 (inputs with a unit) then follow the rule. Locked
  2026-09-27, stage 2 (the finding on unit lists in help rows).
- **D9 — One default decimals rule, from the ladder step.** The default is the
  same on every surface, the source's resolution, and it is a field of the
  ladder step derived from the step's length, covering every token. Higher
  precision for follow-up analysis is a different knob, the existing `-cp,
  --csv-precision` (`full` or a decimal count), not a different default; no sub
  keeps a decimals table of its own. Locked by the architect 2026-09-27, stage 2
  (issue body).
- **D10 — The format's units belong to the format data model.** Verbatim from
  the issue body: "The format data model's per-format defaults (#386) do not yet
  define a format's units, conversion or base unit; that is added there (comment
  on #386, 2026-09-27) and this issue's format-declared default reads it." #386
  is the format data model: default analysis precision per format. Locked
  2026-09-27, stage 2. Its placement of the byte notation is changed by D12.

### Locked 2026-09-28 (the architect's answers to the draft's questions)

- **D11 — GC heap values do not change in this issue.** The GC transform maps
  its suffixes to ladder tokens at today's values (`K` to `KiB`, `M` to `MB`,
  `G` to `GB`, `T` to `TB`) and holds no multiplier of its own; every GC delta
  and self-validation row stays byte-identical. #609 (the GC format declares its
  heap-suffix convention) owns the base-1024 change and the value movement it
  brings; its done-condition ("the heap delta is unchanged") is corrected there
  by a comment. Locked by the architect 2026-09-28.
- **D12 — The format's byte-notation field is added in this issue**, not in
  #386 (format data model: default analysis precision per format): one spec
  field beside the duration unit in the format specs, validated as `si` or
  `iec`, carried onto the registry entry, the GC entry declaring `iec`. A
  comment on #386 (format data model: default analysis precision per format)
  names the field its units declaration absorbs. This is a recorded deviation
  from the 2026-09-27 placement of D10 ("that is added there ... and this issue's
  format-declared default reads it"), locked by the architect 2026-09-28.
- **D13 — A run whose files' formats declare different notations** renders IEC
  only when every file's format declares IEC, else SI, with one notice naming
  the formats that disagree and the option. Locked by the architect 2026-09-28.
  D20 settles the notice under `-bn` and a file no format recognised.
- **D14 — The canonical token is used everywhere.** `-udm v:KB`, `v:kb` and
  `v:kB` all name the column `v_kB_max`, show `kB` in the heading and report
  `unit=kB` in `-V udm-specs`. No notice beyond the release-notes bullet: the
  old column name already flipped between runs. Locked by the architect
  2026-09-28.
- **D15 — One notation per run reaches every byte string the run prints**, the
  tool's own memory rows included (peak memory in the summary, the `-mem`
  breakdown, the aggregate export's `max_memory_used`). The cost is accepted: 43
  of 74 regression captures re-blessed, the bytes histogram screenshot
  regenerated, one release-notes line. Locked by the architect 2026-09-28.
- **D16 — The climb is as locked in D6** (the ladder multiplier compared against
  the raw value, as the count formatter climbs). The rounding carry at a
  boundary (999,999 bytes rendering `1000 kB`) belongs to #617 (one
  width-to-format rule), which owns decimals, and is recorded here as a
  hand-forward (§ 5.11). Locked by the architect 2026-09-28.
- **D17 — The option is `-bn, --byte-notation <si|iec>`**: `si` or `iec` in any
  case, anything else a usage error naming both, honoured from `LTL_CONFIG`
  with the command line overriding. Locked by the architect 2026-09-28.
- **D18 — The ladder step's decimals field is the rounding precision relative to
  the millisecond storage unit** (`ns` 6, `us` 3, `ms` and every longer token
  0). #617 (one width-to-format rule) reads exactly that quantity as its
  ceiling; this issue owns the field and `format_duration`'s rounding to it.
  Locked by the architect 2026-09-28.
- **D19 — Bytes are a tiered kind under the width-to-format rule of #617** (tier,
  fit, decimals), exactly like every other kind. The architect: "As is defined
  in 617, bytes as well have to adhere to output formatting rules just the same.
  These rules established yesterday were in fact primarily focused at bytes."
  This issue's ladder carries the tokens per notation and the climb; #617 (the
  width-to-format rule) owns what each tier renders for bytes; a tier spelling the ladder does not hold is
  added to the ladder step, so the byte vocabulary stays in one table. Locked by
  the architect 2026-09-28.
- **D20 — `-bn` silences the mixed-declarations notice; an unrecognised file
  declares nothing.** On a run whose files' formats declare different byte
  notations, no notice prints when `-bn` is given: the option decides, and the
  declarations decide nothing. A file that no format recognised counts as
  declaring nothing, so a GC-log run that also reads one unrecognised file
  renders SI and prints the one notice of D13, naming the formats that disagree
  and the option. Locked by the architect 2026-09-28.

---

## 5. Design

What restates or follows directly from § 4 is settled and cites the decision.
Implementation detail the architect did not decide is marked **(proposed)**.

### 5.1 Surfaces and sites

| Surface | Site (sub :: snippet) | Today | After |
|---|---|---|---|
| Unit-slot table | `parse_udm_configs` :: `my %byte_units = map { $_ => 1 } qw( B b kB KB MB GB TB KiB MiB GiB TiB );` | private list, eleven spellings | removed; the slot calls the byte resolver (D5) |
| Unit-slot fold | `parse_udm_configs` :: `my %byte_unit_canonical = map { lc($_) => $_ } keys %byte_units;` | collapses `kB`/`KB` and `B`/`b` by hash order | removed (D1, D5) |
| Unit-slot converter | `parse_udm_configs` :: `$converter = sub { convert_bytes($_[0], $unit) };` | hash built per value | multiplies by the step's byte count, captured once at parse (proposed) |
| Byte converter | `convert_bytes` :: `'K'   => 1024,` | sixteen-entry private map, two callers | removed; its two callers read the ladder (D5; § 5.9 for the GC caller) |
| Byte formatter | `format_bytes` :: `if( length( $bytes_int ) >= length( $units{$u} ) ) {` | private IEC map, digit-count climb | reads the run's notation's steps from the ladder, value climb (D6, D7, D16) |
| GC transform | `%format_transform_code` (file scope) :: `gc_heap_delta       => q{ if( defined $heap_from && defined $heap_to ) { $bytes = convert_bytes( $heap_from ) - convert_bytes( $heap_to );` | bare `K` 1024, `M`/`G`/`T` powers of 1000 | suffix mapped to a ladder token at today's value (D11; § 5.9) |
| Format spec field | `format_registry_specs` :: `duration_unit => 'ms', stats_eligible => 1,` | no byte declaration | a `byte_notation` field beside `duration_unit`; the GC entry declares `iec` (D12) |
| Registry entry slot | the `FR_*` slot constants, after `FR_LEVELS          => 29,` | no slot | `FR_BYTE_NOTATION => 30`, set by `build_format_registry` from the spec field (D12; § 5.5) |
| Help, time lists | `print_help` rows for `-bs`, `-du`, `-ru`, `-udm unit` | literals | interpolate the time ladder's list (D8; § 5.6) |
| Help, byte list | `print_help` :: `Bytes: B, kB, KB, MB, GB, TB, KiB, MiB, GiB, TiB. SI: k/K, M, G, T.` | literal, names `KB` as a unit | interpolates the byte ladder's list (D4, D8) |
| Display decimals | file scope before `format_duration` :: `my %duration_display_decimals = ( ns => 6, us => 3, ms => 0, s => 0 );` | four tokens, others 0 | removed; `format_duration` rounds to the step's `decimals` (D9, D18) |
| CSV decimals | `adapt_to_command_line_options` :: `my %decimals_by_unit = ( ns => 9, us => 6, ms => 0, s => 0 );` | four tokens, three more than display | removed; the duration and percentile families read the step's `decimals` (D9, D18) |
| Unknown unit warning | `parse_udm_configs` :: `print STDERR "Warning: Unknown unit '$unit' in -udm '$raw_arg', treating as raw number\n";` | names no vocabulary | lists the time and byte ladders' lists (proposed) |
| Per-metric formatter field | `parse_udm_configs` :: `formatter   => $formatter,` | stored, never read | removed (proposed) |

### 5.2 The byte ladder (D2, D5, D7, D19)

One file-scope table beside `@time_unit_ladder` in the globals, with the same
parts: the steps, one lookup by canonical token, one lookup by lower-cased
spelling, a list for usage messages and help rows, and one resolver (D5). Its
contents follow from D2 and D7:

| Step | SI token | SI bytes | IEC token | IEC bytes |
|---|---|---|---|---|
| byte | `B` | 1 | `B` | 1 |
| kilo | `kB` | 1000 | `KiB` | 1024 |
| mega | `MB` | 1000² | `MiB` | 1024² |
| giga | `GB` | 1000³ | `GiB` | 1024³ |
| tera | `TB` | 1000⁴ | `TiB` | 1024⁴ |

- **Spellings.** Each token is its own only spelling, matched
  case-insensitively (D1). The nine lower-cased tokens (`b`, `kb`, `mb`, `gb`,
  `tb`, `kib`, `mib`, `gib`, `tib`) are all distinct, so the fold is safe: the
  audit's condition "case-folding only where two spellings are not both tokens"
  holds because `KB` is no longer a token of its own (D2). None of the nine
  equals a time-ladder spelling in lower case, so the order of the two
  case-insensitive lookups on the unit slot does not matter.
- **Range.** Byte to tera, the units D2 names. No peta step.
- **Resolver.** One sub returns the canonical token for a spelling, or nothing;
  the `-udm` slot calls it, and the byte inputs of #605 (inputs with a unit)
  will call it. Its name and the table's field names are proposed.
- **Display views.** Per notation, the ordered steps the formatter climbs:
  `B, kB, MB, GB, TB` and `B, KiB, MiB, GiB, TiB` (D7).
- **Tier spellings (D19).** Each step holds one token per notation, the spelling
  every byte surface prints today. Bytes are a tiered kind under the
  width-to-format rule of #617; what each tier renders is #617's, and any tier
  spelling it needs that the step does not hold is added as a field of the same
  step, so the byte vocabulary stays in this one table.

The plain-number multipliers of the unit slot (`k`, `K`, `M`, `G`, `T`, each a
power of 1000, checked case-sensitively first so that `m` stays the minute) are
not byte units and stay as they are (D3). They are a third vocabulary that #605
(inputs with a unit) declares when it gives plain-number inputs a unit; this
issue names that as a hand-forward to #605 (inputs with a unit) and does not
move them. (proposed)

### 5.3 The unit slot (D1, D2, D3, D14)

The resolution order stays: the plain-number multipliers case-sensitively, then
the time ladder, then the byte ladder, each through its resolver; an unknown
spelling warns and is read as a raw number, as today. What changes:

- A byte spelling resolves to one canonical token on every run: `KB`, `kb`, `Kb`
  and `kB` to `kB` (×1000), `kib` and `KIB` to `KiB` (×1024), `b` to `B` (D1,
  D2).
- **The metric keeps the canonical token as its unit** (D14), as a time unit
  already does (`-udm w:minutes:max` names its column `w_m_max`): the CSV column
  (`v_kB_max`), the heading where it carries the unit (two metrics of one name
  told apart by unit, the collision naming `resolve_udm_metric_names` applies)
  and the `read_as: unit=` value of `-V udm-specs` all carry `kB` for any
  spelling of it.
- The converter closure multiplies by the step's byte count, captured at parse;
  no table is consulted per value. (proposed)
- The unknown-unit warning lists the time ladder's and the byte ladder's lists,
  derived from the tables, so a user who typed `KBytes` learns what is accepted.
  (proposed)

### 5.4 The display climb (D6, D16)

`format_bytes` takes a byte count and the decimals it takes today, climbs the
run's notation's steps (§ 5.5) by comparing the value against each step's byte
count, the rule `format_number` :: `if ($value >= $units{$u}) {` uses, and names
the step by its token. It keeps no table. On the boundary fixture of § 3 item 7
(response sizes either side of each step):

| Bytes | Today | SI after | IEC after |
|---|---|---|---|
| 999 | `999 B` | `999 B` | `999 B` |
| 1000 | `1 KiB` | `1 kB` | `1000 B` |
| 1023 | `1 KiB` | `1 kB` | `1023 B` |
| 1024 | `1 KiB` | `1 kB` | `1 KiB` |
| 999,999 | `976.6 KiB` | `1000 kB` | `976.6 KiB` |
| 1,000,000 | `1 MiB` | `1 MB` | `976.6 KiB` |
| 1,048,575 | `1 MiB` | `1 MB` | `1024 KiB` |
| 1,048,576 | `1 MiB` | `1 MB` | `1 MiB` |

The `1000 kB` and `1024 KiB` cells are the rounding carry: the value is below the
next step, and one decimal rounds it up to the step's size. The count formatter
the lock names as the model does the same today (999,999 renders `1000 k` at one
decimal). This issue climbs as locked and leaves the carry in place; it is
handed forward to #617 (one width-to-format rule), which owns decimals (D16,
§ 5.11).

### 5.5 The output notation (D7, D12, D13, D15, D17, D20)

**The option (D17).** `-bn, --byte-notation <si|iec>`, the value matched
case-insensitively, anything else a usage error naming `si` and `iec`, honoured
from `LTL_CONFIG` with the command line overriding. The usage-error text is
proposed: `Invalid byte notation '<value>'. Valid values: si, iec`, the list
derived from the ladder's notations, the same form as the `-du` and `-ru`
rejections.

**The format's declaration (D12).** A format spec in `format_registry_specs` may
carry a `byte_notation` field beside `duration_unit`, `si` or `iec`;
`build_format_registry` validates it at build (anything else fails the build, as
other spec fields do) and carries it onto the registry entry in a new slot,
`FR_BYTE_NOTATION => 30`, after `FR_LEVELS`. The Java GC entry declares `iec`;
every other entry declares nothing. #615 (CSV input as a header-instantiated
registry entry) removes the `FR_TIME_PARSE` slot and renumbers the constants
after it, this one included; whichever of the two lands second rebases the
constants. #386 (format data model: default analysis precision per format)
later absorbs the field into its units declaration.

**Resolution, once per run, after the read.** Every byte surface renders after
every file is read, so the notation is resolved once: from `-bn` if given; else
IEC when every file's format declares IEC; else SI (D13). A file no format
recognised declares nothing, so it does not declare IEC and the run renders SI
(D20). When the files' formats declare different notations and `-bn` is not
given, one notice prints on stderr, as the tool's other behavioural notices do,
whatever `--disable-progress` says; with `-bn` given no notice prints, since the
option decides and the declarations decide nothing (D20). Proposed wording, with
the formats by the names `--help formats` lists:

`Note: the log formats of this run declare different byte notations (<format>: IEC; <format>: none); byte values are shown in SI units. Use -bn si or -bn iec to choose.`

**Reach (D15).** Every surface that renders bytes renders in the run's notation:
the timeline bytes column and a byte-unit `-udm` column, the heatmap scale, the
histogram axes, legend and markers, the messages table, the STATS and MESSAGES
`bytes_nice` cells, and the tool's own memory rows: the summary's peak memory,
the `-mem` breakdown, and the aggregate export's `max_memory_used`, which
`features/503-yaml-aggregate-export.md` D19 (the export's memory value is the
terminal's string) fixes as the same string.

**What changes for a user.** A run over any format that declares nothing (every
access-log, application-log and CSV format today) renders bytes in SI: a bucket
of 1,500,000 bytes reads `1.5 MB` where it read `1.4 MiB`, and the peak memory
row reads `MB` where it read `MiB`. A GC-log run keeps its IEC rendering. `-bn
iec` restores the IEC rendering on any run.

**`-V` surface.** The `format-detection` section gains, beside
`duration_unit_override:` and `format_pin:`, a run-level line
`byte_notation: <si|iec> (<-bn|format <format name>[,<format name>…]|default|mixed>)`, and per
file `byte_notation: <si|iec|->`, the file's format's declaration. Additions
only; the section contract in `features/log-format-registry.md` gains both keys.
(proposed)

### 5.6 Help rows (D4, D8, D17)

The time-unit list below is the canonical tokens joined by commas, the same list
the `-du` and `-ru` rejections print (`ns, us, ms, s, m, h, d, w, month, year`
today); the byte list is both notations' tokens (`B, kB, MB, GB, TB, KiB, MiB,
GiB, TiB`). Neither is written as a literal in the help code.

| Row | After (the list part interpolated) |
|---|---|
| `-du` | the literal list replaced by the time-unit list; wording otherwise unchanged |
| `-bs` | `(units: <time-unit list>; m is always the minute, a month is 30 days and a year 365)` |
| `-ru` | reworded, since its two-part glossed literal cannot be interpolated as it stands (§ 3 item 10): "Set the time unit for rate normalization: any of <time-unit list>; default m (the minute)". The glosses `s (second)`, `h (hour)`, `d (day)` go; the default stays named |
| `-udm unit` | "Time: <time-unit list>. Bytes: <SI byte list> are powers of 1000, <IEC byte list> powers of 1024; case does not matter. Numbers: k/K, M, G, T (×1000 per step). Leave empty for raw numbers (name::max, …), unchanged." Each <…> is the ladder's notation list, interpolated. `KB` leaves the list, being a spelling of `kB`. The number list stays literal until #605 (inputs with a unit) declares that vocabulary (§ 5.2) |
| `-bn` (new) | "Show byte values in SI units (<SI byte list>; powers of 1000) or IEC units (<IEC byte list>; powers of 1024). Default: the log format's convention, else SI." Each <…> is the ladder's notation list, interpolated |
| `-cp` | "per-family decimals derived from the source's duration unit" in place of "derived from -du"; meaning unchanged |

`docs/usage.md` rows cannot interpolate; they carry the same lists, and the
help-content parity scenario (§ 7) fails when either surface stops agreeing with
the ladder. No row names a sub, an issue or a decision. Row wording is proposed;
the interpolation is D8.

**The parity scenario is built here.** One scenario in
`tests/validate-help-content.sh` compares each help row's interpolated list with
the list the matching error prints: the `-du`, `-ru` and `-bs` rows against
their rejections, the `-udm unit` row against the unknown-unit warning, the
`-bn` row against its usage error, and the `docs/usage.md` rows against the same.
This issue lands first of the three that use it: #613 (one name vocabulary)
adds its rows to this scenario, and #525 (a single timestamp-precision option)
edits the `-bs` row in its interpolated form.

### 5.7 Decimals from the ladder step (D9, D18)

Each step of `@time_unit_ladder` gains a `decimals` field, derived from its
length in milliseconds when the table is built: the rounding precision relative
to the millisecond storage unit, the number of decimal places a millisecond
value needs to carry one unit of the step. The values are `ns` 6, `us` 3, and 0
for `ms` through `year`, covering all ten tokens (D18). `format_duration` rounds
to the resolved unit's step `decimals`; the default `-cp` mode's duration and
percentile families take the same value (D9).

| Surface | `-du ns` today → after | `-du us` today → after | `-du ms` and above |
|---|---|---|---|
| Latency cells, messages table (display) | 6 → 6 | 3 → 3 | 0 → 0 |
| STATS and MESSAGES duration and percentile cells, default `-cp` | 9 → 6 | 6 → 3 | 0 → 0 |
| `-V csv-output` `decimals_duration`, `decimals_percentile` | 9 → 6 | 6 → 3 | 0 → 0 |
| `-V csv-output` `max_decimals_ceiling` (default mode) | 9 → 6 | 6 → 5 | 5 → 5 |

The display does not change. The CSV default loses three decimals under `-du ns`
and `-du us`, which shows only on a statistic that is not a whole number of the
source unit (a mean, an interpolated percentile); `-cp 9` or `-cp full` gives the
precision back, as D9 says. The table is the consequence of D9 and D18, not a
new decision.

### 5.8 Records trued up

`features/user-defined-metrics.md` § Unit Types, § Fields (the unit examples),
§ Design Decisions (CSV column naming, D14) and the `-V udm-specs` contract note
on `unit=`; `features/log-format-registry.md` § Format Definition Properties (the
`byte_notation` field, D12), § 11 Unit System (the table naming `convert_bytes`
and `format_bytes`, and the open TODO on the string-length climb) and the
`-V format-detection` section contract; `features/heatmap.md` § `format_bytes()`
Float Handling Bug (the integer-length workaround this replaces);
`features/524-bucket-size-unit.md` § Implementation findings, one line naming the
`decimals` field the ladder gains (D18).

### 5.9 The GC heap-size suffixes (D11)

The GC transform reads `2433M` today through `convert_bytes`' string form: bare
`K` as 1024, bare `M`, `G`, `T` as powers of 1000 (§ 3 item 4). A bare suffix is
not a byte unit under D2 and is not a spelling of the ladder; the JVM writes it in
its own convention, which is the subject of #609 (the GC format declares its
heap-suffix convention).

This issue changes no GC value (D11). The transform reads its suffix through a
GC-local map from suffix to ladder token, `K → KiB`, `M → MB`, `G → GB`,
`T → TB`, which reproduces today's values exactly and holds no multiplier of its
own; the multiplier comes from the ladder step. The GC entry's self-validation
rows (the `2367000000` expectation) and the GC fixture's STATS `bytes` total and
`65 GiB` stay byte-identical through this issue. #609 (the GC suffix
convention) then moves that map into
the GC spec, beside the `iec` notation this issue declares there, and makes the
base-1024 change with the value movement it brings; its done-condition ("the
heap delta is unchanged") is corrected by a comment there (§ 10).

### 5.10 Pattern entries

`docs/architecture-patterns.md` is edited only where this issue's own token
stands in a shared line:

- § Declarative table with one resolver: the byte ladder and its resolver join
  as a consumption site, and the help rows as readers of both ladders. In the
  status line, the byte clause ("the byte-unit slot folds two spellings onto one
  key and resolves nondeterministically") comes out, and the status line's list
  then reads "Refined by #613 (one vocabulary for metric, field, identifier and
  statistic names) and #614 (operand checks and texts derive from the
  vocabulary)."; nothing else in the line changes.
- § One resolution surface per vocabulary: #608 leaves its "Refined by" list;
  nothing else in the line changes.
- § Declarative format registry compiled into generated, cached scan subs: the
  byte-notation field joins the spec fields the registry carries, as the
  format's declared unit convention for bytes.

### 5.11 The seam with #617 (one width-to-format rule)

For the specification of #617 (one width-to-format rule) to cite. Its issue
names this issue as the supplier of
"the byte formatter this rule dispatches to".

| Concern | This issue | #617 |
|---|---|---|
| Byte vocabulary | the ladder: steps, tokens per notation, byte counts, the resolver (D5, D7) | reads the ladder's tokens; any tier spelling it needs is added to the ladder step, never a table of its own (D19) |
| The climb | value-based, the multiplier against the raw value (D6, D16) | unchanged |
| The notation | one per run, resolved after the read (D13, D15, D17) | unchanged; the dispatch passes the run's notation to the byte arm |
| Tiers | bytes carry one token per notation per step today | bytes are a tiered kind like every other: what short, medium and long render for bytes, and the fit (D19) |
| Decimals | the ladder step's `decimals` field, the rounding precision relative to millisecond storage (`ns` 6, `us` 3, `ms` and longer 0), and `format_duration`'s rounding to it (D18) | reads that field as its ceiling; owns width-driven decimals and the trailing-zero helper |
| Boundary carry | leaves 999,999 bytes rendering `1000 kB` (and 1,048,575 rendering `1024 KiB`) as the climb gives them | owns the carry, since it owns decimals (D16) |

Until #617 lands, `format_bytes` keeps its present decimals default and its
present space before the unit. #617 lands after this issue and captures its
regression goldens on the tree this issue leaves.

---

## 6. Acceptance criteria

Each is a condition and an observable outcome, triaged. Fixtures are described
in § 7.

1. **One meaning every run** (assertable; D1, D5). `-udm 'v:KB:max'` on the
   byte-unit fixture, twenty fresh processes: `-V udm-specs` `read_as: unit=`
   and `produced: max=` are identical on all twenty, and the STATS header
   carries the same column name on all twenty. With the bug present, § 3 item 1
   measured six of eight runs reading 1024 for the value and five of eight
   naming the column `v_KB_max`; one fold decides both, so pooled (eleven of
   sixteen) the chance of twenty identical runs is about one in two thousand,
   and the scenario fails on today's tree. Harness: `validate-udm-specs.sh`, new scenario; shape
   `-bs 1440 -oe -ni`, `-o` for the header read.
2. **SI and IEC meanings, case-insensitive** (assertable; D1, D2). Looping the
   ladder: each token and its lower-case, upper-case and mixed-case spellings on
   the unit slot give `produced: max=` of 3 × the step's byte count on values 1,
   2, 3 (`kB`, `KB`, `kb`, `Kb` → 3000; `KiB`, `kib`, `KIB` → 3072; `MB` →
   3,000,000; `MiB` → 3,145,728; and so on to `TB`/`TiB`; `B`, `b` → 3).
   Harness: `validate-udm-specs.sh`; byte-unit fixture, shape `-bs 1440 -oe
   -ni`.
3. **The canonical token everywhere** (assertable; D14). `-udm v:KB`, `v:kb` and
   `v:kB` each report `unit=kB` in `-V udm-specs` and name the STATS column
   `v_kB_max`; `-udm v:KB:max -udm v:MiB:max` shows the two headings as `v:kB`
   and `v:MiB`. No notice prints for a non-canonical spelling. Harness:
   `validate-udm-specs.sh`; byte-unit fixture, `-bs 1440 -oe -ni -o`, the
   heading read from the rendered timeline at a fixed `--terminal-width`.
4. **No assumed base** (assertable; D3). `k` and `K` resolve as a number ×1000
   (`unit=K(number)`) as today; `KBytes` warns with a message listing the time
   and byte ladders' lists, and the metric is read as a raw number. Harness:
   `validate-udm-specs.sh`; byte-unit fixture.
5. **One ladder, read by every byte surface** (assertable, names the mechanism;
   D5, D9). Structural: exactly one byte-unit table exists in `ltl`; no hash or
   list of byte spellings or byte multipliers (`1024**`, `1000**` beside a unit
   spelling) exists outside it; the unit slot, the byte formatter and the GC
   transform read it; no decimals table keyed by a unit exists outside the time
   ladder; `print_help` holds no literal time-unit or byte-unit list (the
   plain-number list k/K, M, G, T stays literal until #605 (inputs with a unit)
   declares that vocabulary, § 5.2). Harness: `tests/validate-byte-units.sh`,
   structural scenario, in the manner of
   `features/524-bucket-size-unit.md` criterion 5 (the structural check that no
   private time table remains).
6. **Value-based climb** (assertable; D6, D16). The boundary fixture, `-o -bs 1
   -ni -bn si`: `bytes_nice` reads `999 B`, `1 kB`, `1 kB`, `1 kB` for 999,
   1000, 1023, 1024; `1 MB` for 1,000,000 and 1,048,576. Under `-bn iec`:
   `999 B`, `1000 B`, `1023 B`, `1 KiB`, and `976.6 KiB` for 1,000,000. Harness:
   `tests/validate-byte-units.sh`.
7. **The boundary carry is handed forward, not fixed** (assertable; D16). The
   boundary fixture under `-bn si` renders 999,999 bytes as `1000 kB`; the
   assertion's contract names #617 (one width-to-format rule) as the owner that
   moves it. The comment on #617 (one width-to-format rule) pointing at § 5.11
   exists at delivery and names the boundary carry (D16), the decimals field as
   its ceiling (D18) and bytes as a tiered kind whose tier spellings are added to
   the ladder step (D19). Harness: `tests/validate-byte-units.sh`; the comment is
   a delivery record (§ 10).
8. **The notation option and the SI default** (assertable; D7, D17). The
   boundary fixture with no option renders SI and reports `byte_notation: si
   (default)`; with `-bn iec`, `-bn IEC` or `--byte-notation iec`, IEC and
   `(-bn)`; with `LTL_CONFIG` carrying `-bn iec`, IEC; with `LTL_CONFIG`
   carrying `-bn iec` and `-bn si` on the command line, SI; `-bn xyz` exits
   non-zero having printed a usage line naming `si` and `iec`. Harnesses:
   `tests/validate-byte-units.sh` reading the STATS `bytes_nice` cell, and
   `validate-format-detection.sh` reading `-V format-detection`.
9. **The format's declaration** (assertable; D7, D12). The committed G1 GC
   fixture with no option renders IEC and reports `byte_notation: iec (format
   java_gc_g1)` and per file `byte_notation: iec`; with `-bn si`, SI. An
   access-log file reports per file `byte_notation: -`. Harnesses:
   `tests/validate-byte-units.sh` for the rendered cells, and
   `validate-format-detection.sh` reading `-V format-detection`; shape
   `-bs 1440 -oe -ni -o`.
10. **Mixed declarations** (assertable; D13, D20). The G1 GC fixture and the
    boundary fixture in one run render SI and print exactly one notice naming
    both formats and `-bn`; the G1 GC fixture given twice renders IEC and prints
    no notice; the mixed pair with `-bn iec` renders IEC and prints no notice
    (D20); the G1 GC fixture beside a file no format recognises (a two-line
    scratch file of plain text) renders SI and prints the one notice, the
    unrecognised file counting as declaring nothing (D20). The notice prints
    under `--disable-progress`. Harnesses:
    `tests/validate-byte-units.sh` reading stderr and the rendered cells, and
    `validate-format-detection.sh` reading `-V format-detection`.
11. **One notation reaches every byte string** (assertable; D15). In one run of
    the boundary fixture with `-hm bytes -hg bytes -mem -o`, under each
    notation, every rendered byte string (the timeline bytes column and a
    byte-unit `-udm` column, the heatmap scale, the histogram axis, legend and
    markers, the messages table, the STATS and MESSAGES `bytes_nice` cells, the
    summary's peak memory row and the `-mem` breakdown) carries only that
    notation's tokens, and the aggregate export's `max_memory_used` carries the same string as the
    peak memory row. Memory values vary between runs, so the assertion reads the
    unit token, not the number. Harness: `tests/validate-byte-units.sh`; the
    export through its documented option.
12. **GC values byte-identical** (assertable; D11). The G1 GC fixture's STATS
    `bytes` total is 69,786,000,000 and its `bytes_nice` `65 GiB`, before and
    after; the GC entry's self-validation rows pass unchanged (they run on every
    invocation). Harness: `tests/validate-byte-units.sh` and
    `validate-format-registry.sh`.
13. **Help rows derive from the ladders** (assertable; D4, D8). The `-du`,
    `-ru`, `-bs` and `-udm unit` help rows carry the list their rejection or
    warning prints (derived from the time ladder); the `-udm unit` row carries
    the byte list the unknown-unit warning prints; the `-bn` row carries the
    notation names the `-bn` usage error prints (`si`, `iec`) and both
    notations' byte lists from the ladder; the `docs/usage.md` rows carry the
    same lists; the `-ru` row names its default. Harness: `validate-help-content.sh`, the new parity scenario, at a
    wide `--terminal-width` so rows do not wrap.
14. **The option surface** (assertable; D17). `-bn` and `--byte-notation` are
    accepted; the help row and the usage row exist and agree. Harness:
    `validate-help-content.sh` scenarios for visible long options in help and
    usage and for short forms matching the option table.
15. **The decimals field's meaning** (assertable; D9, D18). `-V csv-output`
    reports `decimals_duration` 6 under `-du ns`, 3 under `-du us`, 0 under `-du
    ms` and `-du m`; the latency cells render as today
    (`validate-duration-display.sh` passes unchanged); `-cp 9` restores nine
    decimals. Harnesses: `validate-csv-output.sh`,
    `validate-duration-display.sh`; the structural half is criterion 5.
16. **No runtime warnings** (assertable). No ` at <file> line <N>` on stderr in
    any run above. Every harness touched carries the runtime-warning check.
17. **Rendered check** (unassertable: verified by looking at rendered output
    on real data). A day of web-server access log with large responses and a G1 GC log from `docs/test-logs.md`, each under
    both notations and the two together, with a bytes heatmap and histogram and
    `-mem`, inspected on the terminal before the work is called done.

Criterion 17 is unassertable by design (a visual check on real data); no
criterion is unknown.

---

## 7. Verification surface

### `-V` sections

| Section | Read or changed | Contract |
|---|---|---|
| `udm-specs` | read; the `unit=` value becomes the canonical token deterministically (D14) | unchanged keys; the contract's `unit` row gains "the canonical ladder token the spelling resolves to" (`features/user-defined-metrics.md` § `-V udm-specs` section-contract) |
| `format-detection` | changed: a run-level and a per-file `byte_notation` key (§ 5.5) | `features/log-format-registry.md` § `-V format-detection` section-contract; `tests/HARNESS-DESIGN.md` § Reserved section names description |
| `csv-output` | read; values move under `-du ns` and `-du us` (§ 5.7) | unchanged keys; the values follow D9 and D18 |

### Harnesses whose assertions or goldens move

| Harness | What moves | Why the documented contract supports it |
|---|---|---|
| `validate-regression.sh` | 43 of the 74 reference captures carry a rendered byte value, the memory rows included; each non-GC one changes from IEC to SI | D7 and D15: SI is the default where no format declares, on every byte string; the cost is accepted in D15; re-blessed in the drop that changes the default |
| `validate-histogram-ticks.sh` | its reader of rendered legend values (`%unit_scale`) knows `KiB`, `MiB`, `GiB`, `KB`, `MB`, `GB` and not `kB`, `TB`, `TiB`; SI legends would go unparsed | the harness reads the rendered vocabulary; it gains the ladder's tokens |
| `validate-csv-output.sh` | `precision-default-us` scenario: duration decimals 6 → 3, ceiling 6 → 5 | D9, D18; the harness reads the ceiling from the same run's `-V csv-output`, so it follows |
| `validate-udm-specs.sh` | new scenarios (criteria 1 to 4) | D1 to D3, D14 |
| `validate-help-content.sh` | the new parity scenario (criterion 13); the `-bn` row joins the visible-long-option and short-form scenarios | D8, D17, and the new-option rule |
| `validate-format-detection.sh` | new scenarios asserting the run-level and per-file `byte_notation` keys (criteria 8 to 10, the `-V format-detection` half); no existing assertion moves | stability contract: additions are non-breaking |
| `tests/validate-byte-units.sh` (new; asserts the byte-unit feature's rendered cells, no owning `-V` section, named for the feature as `validate-bucket-size-units.sh` is) | criteria 5 to 7, 11, 12 and the rendered-cell half of 8 to 10 | a new harness; no existing assertion moves |
| `validate-screenshot-capture.sh` and `build/screenshots.yaml` | the web-server bytes histogram screenshot regenerates in SI | D7, D15; screenshots are generated, never edited |

### Fixtures

- **Byte-unit fixture** (new, committed, `.txt`): three access-log lines in the
  common-log shape with a duration field, TEST-NET addresses, whose request
  lines carry a query string with a numeric key taking the values 1, 2 and 3.
  Shape `-bs 1440 -oe -ni`: the assertions read `-V udm-specs`, the STATS header
  under `-o`, and the heading for criterion 3.
- **Byte-boundary fixture** (new, committed, `.txt`): nine access-log lines, one
  per minute, with response sizes 999, 1000, 1023, 1024, 999,999, 1,000,000,
  1,048,575, 1,048,576 and 1,500,000. Shape `-o -bs 1 -ni`: one bucket per line,
  the STATS `bytes_nice` cell is the assertion.
- **G1 GC fixture** (existing, `tests/fixtures/gc-g1-categories.txt`): five heap
  transitions in `M`, the IEC declaration, the mixed-declaration run and the
  unchanged-value criterion. Shape `-bs 1440 -oe -ni -o`.
- Both new fixtures recorded in `docs/test-logs.md`.

---

## 8. Measurement obligations

**Before/after benchmark: yes.** Executable lines of `ltl` change, and two of
them run per line (`docs/process/workflow.md` § 3, the row for executable lines
on the hot path). The `before` capture is taken on the base commit before the first line of code:
`single-day-access-log-standard`, labels `608-before` and `608-after`.

That case runs neither a byte-unit `-udm` nor a GC log, so it measures the
display path (per bucket and per row) and the absence of any regression
elsewhere. The two per-line paths this issue touches are measured directly, as
`features/user-defined-metrics.md` § Diagnostics measured its extraction change:
a byte-unit `-udm` metric on the web-server access log of the standard case, and
a G1 GC log, three runs each before and after, median and range of
`parse/read_files`. Both paths lose a per-value hash build (§ 3 item 6), so the
expected effect is neutral or a small gain; a loss larger than the run-to-run
range is investigated. (proposed)

**Prototype: none.** The one data-model addition, a format-spec field and
registry slot, is read once per run after the read, off the hot path. The
per-line change replaces a hash built per call with a multiplier captured once,
a smaller constant on an existing path. Every criterion has a known verification
method. None of `prototype/README.md`'s triggers applies (a new data model, a new
hot-path capability, a costly frequency, an unknown verification method).

---

## 9. Delivery

Drops are commits on the issue branch, each pushed; one PR at the end.

| Drop | Content | Proves |
|---|---|---|
| 1. The byte ladder and the unit slot | the ladder, its resolver and views; the unit slot reads it with the canonical token kept (D14); `convert_bytes` goes; the GC transform reads the ladder through its suffix map at today's values (D11); the unused formatter field goes; the unknown-unit warning lists the vocabularies; `features/user-defined-metrics.md` corrected; `docs/architecture-patterns.md` § Declarative table with one resolver and § One resolution surface per vocabulary edits of § 5.10 | criteria 1 to 4, 12, 16 |
| 2. Help rows | `-du`, `-ru`, `-bs`, `-udm unit` rows interpolate the ladders; `docs/usage.md` rows agree; the parity scenario | criterion 13 for the `-du`, `-ru`, `-bs` and `-udm unit` rows |
| 3. Notation and display | the value climb; the `byte_notation` spec field, its slot and the GC declaration; the `-bn` option with help and usage rows; the resolution and its notice; the `-V format-detection` keys, with the `-V format-detection` section contract in `features/log-format-registry.md`, `tests/HARNESS-DESIGN.md` § Reserved section names, and the § Declarative format registry line of § 5.10, in the same commit as the keys; the `-bn` row joins the parity scenario; the memory rows in the run's notation; regression captures re-blessed; histogram-ticks reader updated; screenshot regenerated | criteria 6 to 11, 13 (the `-bn` row), 14, 17 |
| 4. Decimals | the `decimals` step field; both tables go; `-V csv-output` values follow; the `-cp` help and usage row wording (§ 5.6) | criteria 5 and 15 |

Drop 1 alone fixes the reported defect. Drop 3 is the one that changes rendered
output on every run and carries the re-blessed captures. The order of drops is
proposed.

**Ordering edges.** Recorded as native blocked-by relationships in this stage,
before the PR: #617 (one width-to-format rule) blocked by #608, and #616 (one
gated derivation of means and totals) blocked by #608. The edges to #605
(inputs with a unit) and #609 (the GC format's suffix convention) already exist.

**Merge gate.** `$version_number` restored to `0.19.0`; the full harness suite
on the commit being merged (`CI=1 validate-csv-output.sh`, then
`CI=1 validate-statistics.sh`, then the rest), each summary showing assertions
ran; the before/after benchmark of § 8 on this machine, nothing worse than the
run-to-run range; `validate-help-content.sh` passing; the rendered check of
criterion 17 done.

---

## 10. Records to update (a record whose subject a drop changes is updated in that drop's commit; the rest at delivery)

| Record | Update |
|---|---|
| `features/user-defined-metrics.md` | § Unit Types, § Fields, § Design Decisions (CSV naming by the canonical token), `-V udm-specs` contract note |
| `features/log-format-registry.md` | § Format Definition Properties (the `byte_notation` field), § 11 Unit System, `-V format-detection` section contract |
| `features/heatmap.md` | § `format_bytes()` Float Handling Bug: the workaround is replaced by the value climb |
| `features/524-bucket-size-unit.md` | § Implementation findings: the `decimals` step field |
| `docs/architecture-patterns.md` | the three lines of § 5.10, this issue's tokens only |
| `tests/HARNESS-DESIGN.md` | § Reserved section names: the `format-detection` description |
| `docs/test-logs.md` | the two new fixtures |
| `docs/usage.md` | the `-udm unit`, `-du`, `-ru`, `-bs` rows; a new `-bn` row; the `-cp` row wording |
| `--help` | the same rows |
| `features/342-redundant-logic-surfaces-audit-report.md` | § Review progress, stage 2: status *done* when this issue closes; § Item 1 inventory corrected for the converter's callers (§ 3 item 5) |
| Native edges | #617 (one width-to-format rule) blocked by #608; #616 (one gated derivation of means and totals) blocked by #608 |
| Comment on #609 (the GC format's heap-suffix convention) | § 3 item 4 and § 5.9: the GC values are parsed SI today; this issue maps the suffixes at today's values (D11); #609 owns the base-1024 change; its done-condition "the heap delta is unchanged" is corrected, since the base-1024 change moves the delta |
| Comment on #386 (format data model: default analysis precision per format) | the `byte_notation` spec field added here (D12), which its units declaration absorbs |
| Comment on #617 (one width-to-format rule) | § 5.11: the boundary carry (D16), the decimals field as its ceiling (D18), bytes as a tiered kind with tier spellings added to the ladder step (D19), and the edge |
| Comment on #616 (one gated derivation of means and totals) | the edge and its reason: regression goldens re-blessed here first |
| Comment on #605 (inputs with a unit) | the byte resolver it calls, and the plain-number vocabulary it inherits (§ 5.2) |
| Comment on #615 (CSV input as a registry entry) | the `FR_BYTE_NOTATION` slot constant its renumbering covers; whichever lands second rebases |
| Comment on #613 (one name vocabulary) | the help-content parity scenario it adds its rows to (§ 5.6) |
| Comment on #525 (a single timestamp-precision option) | the `-bs` help row is interpolated here; its edit starts from that form |
| Release notes | three bullets: "Fix `-udm` byte units resolving differently between runs: `KB` always means 1000 bytes, and the column carries the canonical unit.", "Show byte values in SI units by default, or in a log format's declared notation; `-bn iec` shows KiB and MiB. See docs/usage.md." and "Set CSV duration decimals to the source unit's resolution under `-du ns` and `-du us`; `-cp` gives more. See docs/usage.md." |

---

## 11. Implementation progress

### Drop 1 — the byte ladder and the unit slot (2026-09-29)

**Built.** `@byte_unit_ladder` at file scope beside `@time_unit_ladder`: five
steps, each carrying an `si` and an `iec` part of `{ token, bytes }`; the views
`%byte_unit_bytes` (token to byte count), `%byte_unit_by_spelling` (lower-cased
token to token) and `$byte_unit_list` (every token, SI then IEC, `B` once); the
resolver `byte_unit_canonical()`. `parse_udm_configs` resolves the unit slot as
number multiplier (case-sensitive), then `time_unit_canonical()`, then
`byte_unit_canonical()`; the byte converter multiplies by the step's byte count
captured at parse. Its private byte list and fold, and the unread `formatter`
field, are gone. `convert_bytes` is gone; the GC transform calls
`gc_heap_size_bytes()`, which reads the suffix through
`%gc_heap_suffix_token` (`K` `KiB`, `M` `MB`, `G` `GB`, `T` `TB`) and takes the
multiplier from the ladder (D11). The unknown-unit warning appends
`(time units: <time list>; byte units: <byte list>)`, both interpolated.

**Correction to criterion 4.** `k` reports `unit=k(number)`, not
`unit=K(number)`: a number multiplier is kept as typed, as before this issue.
The harness asserts `unit=<spelling>(number)` and the ×1000 value.

**Behaviour of the GC reader outside the JVM's form.** A heap size that is not
digits followed by `K`, `M`, `G` or `T` reads as 0 bytes. The removed converter
multiplied by an undefined table entry there, which gave 0 with a runtime
warning; no line of the committed G1 fixture or of the G1 GC logs of the corpus
takes that path.

**Proof.** `tests/validate-udm-specs.sh` scenarios `byte-unit-one-meaning`
(criterion 1), `byte-unit-meanings` (2), `byte-unit-canonical-token` (3) and
`number-multiplier-and-unknown-unit` (4), 60 assertions, pass; run against the
base commit's `ltl` they fail 11 assertions (the one-meaning pair, the `kB` and
`B` spellings the hash-order fold flipped, the column name, the headings, the
warning). The new `tests/validate-byte-units.sh` scenario
`gc-heap-values-unchanged` (criterion 12) passes: exit 0 with the GC entry's
self-validation rows, STATS `bytes` 69786000000 and `bytes_nice` `65 GiB`; with
`M` sabotaged to `MiB` it fails on the self-validation row (got 2481979392,
expected 2367000000). The G1 fixture's STATS and MESSAGES CSVs are
byte-identical between the base and this drop. `validate-udm-specs.sh` (186)
and `validate-format-registry.sh` (24) pass whole.

**Per-line measurement (§ 8).** Three runs each, `parse/read_files` seconds,
base 99fd43a against this drop, on one machine. Byte-unit metric: the
web-server access log of the standard benchmark case with
`-udm '_twsr:KB:max'` (643,366 values). G1: the largest G1 GC log of the corpus
(781,118 lines).

| Path | Before, median (range) | Drop 1, median (range) | Change |
|---|---|---|---|
| byte-unit `-udm` | 12.470 (12.225–12.606) | 11.371 (11.193–11.442) | −8.8 % |
| G1 GC heap delta | 8.666 (8.573–8.681) | 7.633 (7.575–7.679) | −11.9 % |

Both gains are the per-value hash build of the removed converter (§ 3 item 6);
the `-V` output of each pair differs only in a timing row. The
`single-day-access-log-standard` before benchmark is captured as `608-before`
on 99fd43a; the after capture runs at the completion gate.

### Drop 2 — help rows (2026-09-29)

**Built.** Two views beside `$byte_unit_list`: `$byte_unit_si_list` (`B, kB,
MB, GB, TB`) and `$byte_unit_iec_list` (`KiB, MiB, GiB, TiB`, the tokens only
IEC has); `$byte_unit_list` is now the two joined, so the unknown-unit warning
prints the same list as before. The `-du`, `-bs` and `-udm unit` help rows
interpolate `$time_unit_list`; the `-ru` row reads "Set the time unit for rate
normalization: any of <time list>; default m (the minute)"; the `-udm unit` row
reads "Time: <time list>. Bytes: <SI list> are powers of 1000, <IEC list>
powers of 1024; case does not matter. Numbers: k/K, M, G, T (powers of 1000)."
`KB` has left the list. The number clause says "powers of 1000" where § 5.6
proposed "×1000 per step": plain text, and the same words as the byte clause.
The `docs/usage.md` `-ru` and `-udm unit` rows carry the same text; the `-du`
and `-bs` rows already carried the list.

**Proof.** `tests/validate-help-content.sh` scenario `J-unit-list-parity`
(criterion 13 for the `-du`, `-ru`, `-bs` and `-udm unit` rows), 11 assertions:
it reads the list from the `-du`, `-ru` and `-bs` rejections and the `-udm`
unknown-unit warning, requires the four time lists to agree, then requires each
help row and each `docs/usage.md` row to carry its list (and the `-udm` row's
two byte lists joined to equal the warning's). Against the base commit's `ltl`
and `docs/usage.md` it fails 7; with the `docs/usage.md` `-du` row missing
`year` it fails that one row. `validate-help-content.sh` (33) and
`validate-help-layout.sh` (6) pass whole. The `-bn` row joins the scenario in
drop 3; the structural check that `print_help` holds no literal list is
criterion 5, in drop 4.

