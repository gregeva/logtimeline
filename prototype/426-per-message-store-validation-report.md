# Validation report — issue #426 compact per-message statistics store

Prototype stage for `features/426-per-message-statistics-store.md`. Every number
below is a median with its min–max range over 5 timed runs (one untimed warmup for
the traversal metrics), one arm and one fixture per process so each arm builds its
store on a fresh heap. Parity across arms is asserted from digests of every stored
field for every key, of the top-10 selection of both sort shapes, and of the store
after deletion churn — the matrix driver exits non-zero on any divergence, and no run
reported here diverged.

Environment: Apple M1 Pro, 32 GB, macOS (Darwin 25.5.0), `/opt/homebrew/bin/perl`
5.42.2, `Devel::Size` 0.87. Tree: `426-per-message-statistics-store` @ `ffc6f23`
(on `release/0.17.0` @ `09262f7`). Fixtures: `prototype/426-generate-fixtures.sh`
(deterministic `head` slices; `twx-unique` 1k/10k/100k/full = 288,025 lines of the
humungous-log-uniqueness source, 286,754 distinct keys at full; `access` 1k…1M lines
of the Tomcat access log, 3,562 distinct keys at 1M).

Arms (`prototype/426-store-mini.pl`): **A** production store and code verbatim;
**B** A + comparator hoist (sort metric extracted once into a flat array); **C** A +
`my $entry` aliasing across the read-loop write block; **D** columnar — per-category
message→ordinal hash + one array per demanded field, ordinal→key column built after
the read loop with `each`; **D2** D with one hash operation per line (`//=` insert)
and the key column built with `keys` + slices; **D3** D2 with the key column written
at insert time (a second copy of every key string). The E hybrid of the spec (lazy
per-ordinal cold hash for rare fields) is folded into D: no cold field is ever
written on these fixtures, so D and E are one arm here.

## Validation aspects

| id | question (feature-doc Q) | instrument |
|---|---|---|
| V1 | Q1 — does a columnar store realise the L2 traversal gain on the store *as the real read loop built it*? | `426-asbuilt-probe.pl` injected into a throwaway `ltl` before `calculate_all_statistics();` |
| V2 | Q2 — what does the ordinal scheme cost on the write side, per line? | mini, `build_ns_per_line`, both families, 1k → 1M |
| V3 | Q3 / Q12 — memory of the columnar store vs the hash store; the residual of the 45.8% ceiling | mini, RSS delta + `Devel::Size` |
| V4 | Q4 — deletion under `-g`-like churn: tombstones, compaction | mini, `churn_*` / `compact_*` |
| V5 | Q10 — do the cheap arms B / C close enough of the gap? | mini, B and C vs A vs D |
| V6 | ordinal→key column: post-read (`each` / slices) vs insert-time copy | mini, D / D2 / D3 |

## V1 — As-built traversal (Q1)

### Hypothesis

The #415 ladder showed the as-built entry hashes cost 5× on keyed traversal versus the
same hashes rebuilt into fresh memory (L2). A columnar store should match or beat L2,
because its per-key state lives in arrays whose layout does not depend on the read
loop's allocation history — and it should do so on the real heap, not only in a
standalone process.

### Method

The probe runs inside `ltl` on the store exactly as the production read loop left it
(`-so p99 -ni -mem --terminal-width 200`), measures the three traversal shapes of the
statistics phase on L0 (as built) and L2 (entries rebuilt into fresh memory, the
ladder's level), then converts L0 in place into the columnar shape (`%ord`, `@occ`,
`@key`) and measures the same shapes on it. `lookup` is the comparator-shaped keyed
loop; `walk` is the population walk of the calculated-statistic branch; `sort` is the
two-stage fill-block selection with the key tiebreaker (the block the construct
actually runs — every key is tied at occurrences = 1, so the pool is the whole
population). ltl's own `-V benchmark-data` rows from the same process cross-validate
the probe's shapes.

### Result

`twx-unique-full` (286,659 keys in the real process):

| shape | L0 as built | L2 rebuilt | D columnar | D vs L0 | D vs L2 |
|---|---|---|---|---|---|
| lookup (keyed) | 0.1696 (0.1659–0.1779) | 0.0351 (0.0347–0.0358) | 0.0452 (0.0449–0.0457) | 3.8× | 0.78× |
| walk | 0.2604 (0.2479–0.2708) | 0.1348 (0.1336–0.1357) | 0.0456 (0.0440–0.0481) | **5.7×** | 3.0× |
| sort (fill block) | 0.2357 (0.2350–0.2493) | 0.1009 (0.0986–0.1011) | 0.0230 (0.0223–0.0253) | **10.2×** | 4.4× |

`twx-unique-100k` (99,487 keys): lookup 0.0417 / 0.0084 / 0.0111; walk 0.0736 /
0.0396 / 0.0127; sort 0.0571 / 0.0298 / 0.0057 — the same ratios (walk 5.8×, sort
10×). Top-10 selection identical across L0 / L2 / D at both sizes.

Cross-validation, same process, full file: ltl reports `population_walk 0.254` and
`sort_selection 0.245`; the probe's L0 walk and sort are 0.260 and 0.236 — within 3%.
The probe's L0 `Devel::Size` (133,188,000) matches the record's `MEMORY log_messages`
133,188,237 B. A plain run without the probe on this tree gives `population_walk
0.290`, `sort_selection 0.277`, `calculate_statistics 0.580`.

### Surprises

- The columnar walk and sort are faster than **L2**, the fresh-memory hash the ladder
  used as its floor — the ladder's 5× was an upper bound on *hash* layouts, not on
  what a denser representation could reach. On the keyed lookup D is 22% slower than
  L2 (one hash probe plus an array index versus one hash probe plus a small-hash
  probe on a contiguous entry), which is irrelevant to the production shapes: the
  columnar comparator indexes arrays, it does not look keys up.
- The in-place conversion costs 0.278 s (0.261–0.294) at 287k keys — more than the
  traversal it saves in one run. It is a migration cost, not a production path; the
  production store is built columnar from the first line (V2).
- With the probe injected, ltl's later `MEMORY log_messages` row read 165,294,045 B
  instead of 133,188,237; the plain run reproduces the record's figure. The probe
  perturbs that one downstream measurement (mechanism not investigated — it is an
  instrument, not production code) and its own pre-statistics figure is the correct
  one.

### Findings and actions

- **Q1 answered: yes.** On the real as-built store the columnar shape is 5.7× faster
  on the population walk and 10× on the selection sort — beyond the ladder's L2
  floor. The cost the ladder attributed to heap placement is removed, not relocated.
- On the measured construct this is 0.254 + 0.245 = 0.50 s of a 0.58 s statistics
  phase reduced to ≈ 0.07 s of traversal — plus the ordinal→key column cost of V6.

### Reproduction

```bash
./prototype/426-asbuilt-run.sh ./ltl /tmp/ltl-426-fixtures/twx-unique-full.log /tmp/426-asbuilt-full.out
./prototype/426-asbuilt-run.sh ./ltl /tmp/ltl-426-fixtures/twx-unique-100k.log /tmp/426-asbuilt-100k.out
```

## V2 — Write side per line (Q2)

### Hypothesis

The ordinal scheme adds a hash lookup and an array store per line where the hash
store does one autovivifying statement; on the non-access path (one field per entry)
that could cost a measurable fraction of the ~3 µs the mini spends per line.

### Method

`build_ns_per_line` = whole per-line path (regex capture into lexicals, key
derivation verbatim, the per-bucket side hash, the store write), file read inside
the timed region, first build kept for the later metrics. Non-access path: arm A's
write is the single production statement `$log_messages{$category}{$log_key}{occurrences}++`
(C is byte-identical to A there). Access path: the full raw-mode write block
(lazy init, occurrences, bytes, count branch, UDM loop, duration accumulators,
`durations[]` push, impact).

### Result

| fixture | A | B | C | D | D2 | D3 |
|---|---|---|---|---|---|---|
| twx-unique-10k | 3103 (3070–3188) | 3105 (3045–3196) | 3112 (3042–3238) | 3255 (3164–3448) | 3183 (3154–3239) | 3212 (3157–3316) |
| twx-unique-100k | 3366 (3328–3503) | 3334 (3299–3381) | 3413 (3274–3500) | 3480 (3402–3652) | 3405 (3347–3498) | 3448 (3409–3828) |
| twx-unique-full | 3500 (3403–3640) | 3435 (3401–3577) | 3518 (3412–3648) | 3537 (3474–3567) | 3382 (3347–3433) | 3495 (3469–3593) |
| access-10k | 3517 (3483–3580) | 3490 (3479–3518) | 3066 (3052–3134) | 3037 (3008–3112) | 3064 (3017–3075) | 3065 (3045–3080) |
| access-100k | 3482 (3469–3492) | 3526 (3489–3546) | 3091 (3061–3122) | 3009 (2995–3036) | 3052 (3022–3105) | 3028 (3015–3049) |
| access-1m | 3609 (3578–3664) | 3610 (3575–3647) | 3119 (3106–3149) | 3089 (3067–3130) | 3090 (3072–3141) | 3146 (3115–3192) |

ns per line. Non-access: D/D2/D3 are within −3% … +5% of A (full: +1% / −3% / 0%),
inside the min–max spread of A itself (two earlier matrices on the same fixtures put D
at +10% and +3% at full — the run-to-run spread of this metric is ±5–10%, so the
honest statement is "not distinguishable from A"). Access: **C, D, D2 and D3 are all
−13% … −15% versus A at every size**, ≈ 450–500 ns per line, and are indistinguishable
from each other.

### Surprises

- The write-side saving on the access path is entirely the *aliasing* (one resolution
  of `$log_messages{$category}{$log_key}` per line instead of ~9): C gets all of it
  without changing the data model, and D adds nothing on top — nor does it cost
  anything. The mini's per-line total is ~3.5 µs; production's read loop is ~7.4 µs
  per line on this file, so the saving is ≈ 6% of the production per-line cost on
  access logs.
- D's double hash operation on a new key (miss, then store — the 200-char key hashed
  twice) did not show up above noise; D2's single-operation `//=` insert is the
  cleaner shape but is not measurably faster.

### Findings and actions

- **Q2 answered: the ordinal scheme is write-side neutral** on the path that
  dominates the construct, and −14% on the multi-field access path — a gain that
  belongs to aliasing and is available to any store shape.
- Arm C's aliasing is worth taking regardless of the store decision; a columnar store
  gets it by construction (the column handles are resolved once per category, F6).

### Reproduction

```bash
./prototype/426-generate-fixtures.sh
./prototype/426-run-matrix.sh /tmp/ltl-426-results 5 "A B C D D2 D3" /tmp/ltl-426-fixtures/*.log
perl prototype/426-pivot.pl /tmp/ltl-426-results/results.tsv
```

## V3 — Memory (Q3, Q12 residual)

### Hypothesis

The record decomposed the 465 B/key store into 213 B/key of inner entry hash
(replaceable) and 252 B/key of key strings + outer hash (not replaceable), a ceiling
of −46% *if* the replacement's own per-key arrays cost nothing. They will not.

### Method

RSS delta from process start to the end of the first build (the truth: `Devel::Size`
cannot see that D's key column shares the hash's HEK strings and counts every key
twice), plus `Devel::Size::total_size` of the store for the composition.

### Result

`twx-unique-full`, 286,754 keys:

| arm | RSS after build | vs A | Devel::Size | of which key column |
|---|---|---|---|---|
| A (B / C: 149,344 kB) | 146,240 kB | — | 133.2 MB | — |
| D | 111,392 kB | **−23.8%** | 106.0 MB (overcounted) | 78.8 MB (overcounted) |
| D2 | 111,456 kB | −23.8% | 106.0 MB (overcounted) | 78.8 MB (overcounted) |
| D3 | 192,080 kB | **+31.3%** | 163.8 MB | 69.5 MB (real copies) |

100k: A 54,096 kB, D 38,464 kB (−28.9%), D3 67,584 kB (+24.9%). Access family: no
difference between arms at any size (the store is dominated by the `durations[]`
arrays, identical in every arm; 84–85 MB at 1M for 3,562 keys).

Composition of D's saving at full: A's inner entry hashes are 61 MB (213 B × 287k);
D's ordinal column (8 B slot + 24 B integer SV) and its HEK-sharing key column
(8 B slot + ~40 B SV) together cost ≈ 23 MB; net −35 to −38 MB, which is what RSS
shows (146–149 → 111.4 MB).

### Surprises

- `Devel::Size` reports D at 106 MB and its key column at 79 MB; the key column's real
  cost is ≈ 14 MB (shared HEKs). D3 shows the alternative: writing the key at insert
  time costs the full second copy, +80 MB, and RSS ends 29% *above* A.
- An undemanded column costs nothing: the twx D store instantiates exactly one field
  column (`occ`); the access D store instantiates seven. Nothing is written for a
  field a family does not produce (Q3).

### Findings and actions

- **Q12 residual answered:** D realises −25% of the store's RSS, i.e. ≈ 62% of the
  46% ceiling; the rest is D's own per-key arrays. #2's per-entry arithmetic (F10)
  can now be re-derived against ≈ 80 B/key of columnar overhead instead of 213 B/key
  of entry hash.
- **Q3:** column existence is decided at option-resolution time per family/demand;
  no per-line gating is needed (twx D allocates one column and never tests for the
  others on the hot path).

## V4 — Deletion churn (Q4)

### Hypothesis

Under `-g` most keys are deleted after being merged into clusters, then clusters are
injected as new keys. A hash frees each deleted entry; a columnar store can only
tombstone the ordinal, so its arrays keep their length until a compaction pass, and
every later traversal scans the holes.

### Method

On the built store: sort the keys (the final pass iterates sorted keys), read each of
the first 90% (the merge reads the entry) and delete it, inject 1% new cluster keys;
time that; then re-measure the walk and fill sort, `Devel::Size`, and the RSS delta
across the churn. D arms additionally run a compaction pass (drop tombstoned
ordinals, slice every column in place, renumber the ordinal hash in place) and
re-measure.

### Result

`twx-unique-full` (258,078 deleted, 2,867 injected, 31,543 live):

| metric | A | D | D2 | D3 |
|---|---|---|---|---|
| churn (delete + inject) | 0.2884 | 0.2558 (0.89×) | 0.2603 | 0.3024 |
| RSS delta across churn | +0.4 MB | +3.4 MB | +3.5 MB | +3.4 MB |
| walk after churn | 0.0326 (0.0316–0.0373) | 0.0162 (0.0160–0.0162) | 0.0162 | 0.0168 |
| fill sort after churn | 0.0590 (0.0572–0.0607) | 0.0046 (0.0045–0.0058) | 0.0045 | 0.0048 |
| `Devel::Size` after churn | 28.3 MB | 43.5 MB (tombstoned, key column overcounted) | 43.5 MB | 101.3 MB |
| compaction | — | 0.0649 | 0.0671 | 0.0829 |
| walk after compaction | — | 0.0041 (0.0040–0.0043) | 0.0040 | 0.0046 |
| fill sort after compaction | — | 0.0037 (0.0033–0.0043) | 0.0032 | 0.0043 |
| `Devel::Size` after compaction | — | 23.6 MB | 23.6 MB | 29.2 MB |

100k: churn A 0.0839 / D 0.0671; compaction 0.0163; D walk 0.0056 tombstoned →
0.0014 compacted.

### Surprises

- Tombstoning is slightly *cheaper* than deleting hash entries (0.26 vs 0.29 s; 0.23
  vs 0.30 in the previous run): undef-ing a column slot is less work than freeing a
  six-piece entry hash — on a one-column store. With 26 columns (bin mode, V7) it is
  the other way round.
- Even tombstoned (89% holes), D's post-churn walk and sort are 2× and 13× faster
  than the hash arm's; after a 0.065 s compaction the store is smaller than the hash
  arm's post-delete store (23.6 vs 28.3 MB by `Devel::Size`, and the hash arm's figure
  is not overcounted).
- Neither arm returns memory to the OS across the churn; the RSS delta is noise
  either way. The memory that matters after `-g` is the live structure, which
  compaction settles.

### Findings and actions

- **Q4 answered: tombstones + one compaction pass at the end of the `-g` final
  pass.** Cost at 287k keys: 0.064 s once; no per-delete cost above the hash's; every
  traversal afterwards runs on dense arrays. A tombstone is a single `undef` in the
  ordinal's occurrences slot; walks skip it; the ordinal hash entry is deleted so
  `exists` semantics are unchanged.
- The field-level `delete …{total_duration}` (#330) becomes an `undef` of that
  column's slot — same read semantics under `defined` / `//`.

## V5 — Cheap arms (Q10)

### Hypothesis

If a Schwartzian transform of the comparator (B) and entry aliasing (C) close most of
the gap, a 167-site data-model change is not justified.

### Method

B: the sort metric is extracted once into a flat array and both sort stages compare
array elements, keys resolved at the end. C: the read loop resolves the entry once.
Both measured against A and D on the same shapes.

### Result

`twx-unique-full`, traversal:

| shape | A | B | C | D |
|---|---|---|---|---|
| walk | 0.2759 (0.2423–0.3105) | 0.2791 | 0.2619 | 0.0397 (0.0389–0.0410) |
| sort, available-value branch | 0.3095 (0.2997–0.3146) | 0.2850 (0.2756–0.2893) | 0.3141 | 0.0181 (0.0179–0.0182) |
| sort, fill block | 0.2682 (0.2605–0.2807) | 0.2760 (0.2729–0.2802) | 0.2501 | 0.0225 (0.0221–0.0234) |
| keyed lookup, as built | 0.1457 | 0.1452 | 0.1433 | — |

100k: A sort 0.0742 / B 0.0693 / D 0.0061; 10k (keys no longer all tied, so the sort
does real comparisons): A 0.0294 / B 0.0120 / D 0.0114.

### Surprises

- **B does not move the needle at 287k keys**: −8% / +3% in this run, +19% / +44%
  in the previous one — within run-to-run noise of A either way, against D's 15×.
  It wins at 10k (0.41×), where the keys are not all tied and the sort performs
  O(n log n) comparisons whose per-comparison hash lookups B removes. At 287k every
  key is tied, the sort performs ~n comparisons, and the cost is the first
  dereference of each scattered entry — which B's extraction pass pays in full, plus
  a 287k-element list, a 287k-element value array and the index→key resolution.
- C is neutral on this path (its statement is A's statement) — its −14% belongs to
  the multi-field write path (V2), not to traversal.

### Findings and actions

- **Q10 answered: no.** B is falsified (fails to close the comparator gap at the
  cardinality that motivates the issue). C is a write-side gain independent of the
  store and is subsumed by D. A new data model is needed for the traversal cost.

## V6 — Ordinal→key column

### Hypothesis

The selection sort's tiebreaker (`$a cmp $b`) and the display need the key for an
ordinal. Hash keys live only in the hash; a reverse map costs either a post-read pass
(D: `each`; D2: `keys` + slices) or a second copy of every key string at insert time
(D3).

### Result

`twx-unique-full`:

| | D (`each`) | D2 (`keys` + slices) | D3 (insert time) |
|---|---|---|---|
| reverse-map pass | 0.1298 (0.1294–0.1311) | 0.1303 (0.1284–0.1317) | 0 |
| memory (RSS vs A) | −23.8% | −23.8% | +31.3% |
| fill sort | 0.0225 | 0.0226 | 0.0551 (2.4× slower) |
| available-value sort | 0.0181 | 0.0181 | 0.0547 |
| walk | 0.0397 | 0.0400 | 0.0441 |

100k: pass 0.0356 / 0.0315 / 0; sort 0.0067 / 0.0067 / 0.0095.

### Surprises

- The slice form buys nothing: iterating a 287k-key hash to materialise its key SVs
  costs ≈ 0.13 s (450 ns/key) whichever way it is spelled — it is the same cost A's
  population walk pays inside `foreach (keys %{…})`, relocated.
- D3's insert-time copies make the tiebreaker sorts 2.4× slower than D's HEK-sharing
  column — plausibly the copies' SV heads and buffers are laid down in read-loop order
  (the very scatter the issue is about), whereas the post-read column's SV heads are
  allocated in one burst; not verified.

### Findings and actions

- **Post-read, HEK-sharing key column (D / D2).** Total D traversal on the construct is
  walk 0.040 + key column 0.130 + sort 0.023 = **0.19 s versus A's 0.54 s (2.8×)**; the
  columnar part alone is 8.6×. The 0.13 s is the floor of "get every key out of a
  Perl hash once" and is paid by A too.
- The pass is needed only when a consumer asks for keys by ordinal (selection
  tiebreak, display, CSV, consolidation) — one lazily built column per category per
  run, invalidated by compaction.

## V7 — The `-mdm bin` stores (Q7, #354)

### Hypothesis

Under `-mdm bin` a message has two stores: the record (with the Welford-Pébay
sidecars as fields) and a #189 bin-counter entry in `%log_messages_counters`, keyed
by a composite `"$category\x1f$log_key"` string. The counter entry is three
containers — an outer hash, a 7-field partition hash, and a bins array dense from
index 0 whose occupied slots sit ~130 in (the partition is seeded ±2.5 decades
around the first sample) — so it should dominate per-message memory (#354 measured
2,327 B/entry) and the percentile pass (which sums the whole array once per
quantile). Columns for the record and a span-only bins representation should remove
most of both.

### Method

`prototype/426-bin-store-mini.pl`, same protocol as the raw mini (one arm and one
fixture per process, 5 runs, parity digests over every record field, the canonical
bins of every key, the partition geometry, and the derived statistics; the driver
exits non-zero on divergence — none diverged). Production keying reproduced exactly
(thread-pool reduction of the thread name, `count=` extraction and mask): 3,421 keys
on the DPM log, as ltl reports.

Arms: **K1** today (hash record + composite-keyed counter hash; every primitive
verbatim). **K2** columnar record, counter entries as today's hashes held in an array
by row. **K3** columnar record + counter *columns* (partition min / max / bin_count /
log_ratio / rebins, overflow, underflow) with bins dense as today; assignment inlined.
**K4** K3 with offset-dense bins (`[base_index, c0, c1, …]` — only the occupied span).
Partition widening in K3/K4 runs the verbatim `partition_extend` through a column
view, so the geometry is byte-identical.

`population_stats` = the `-so p99` population pass: eligibility + the
`calculate_statistics_bin` derivation (min/max/mean/std from the sidecars, four
quantiles from the counter) for every eligible key — the block ltl reports as
`population_walk` in bin mode.

Fixtures: `bin-dpm-*` — the metric-dense ScriptLog, real durations, 3,421 keys × ~36
samples, 116 partition widenings (the percentile-traversal case); `bin-twxdur-*` —
**synthetic**: the 287k-message log with a deterministic ` durationMs=N` appended
(the high-cardinality memory case; no corpus file has both).

### Result

`bin-dpm-full` (122,808 lines, 3,421 keys):

| metric | K1 today | K2 by row | K3 columns | K4 + span bins |
|---|---|---|---|---|
| write, ns/line | 9,242 (9,204–9,758) | 7,503 | 6,910 | **6,971** (−25%) |
| RSS after read | 17.4 MB | 16.3 MB | 15.2 MB | **11.0 MB** |
| record store (`Devel::Size`) | 5.36 MB | 2.89 MB | 2.90 MB | 2.90 MB |
| counter store (`Devel::Size`) | 9.65 MB | 8.84 MB | 6.77 MB | **3.93 MB** |
| `-so p99` population pass | 0.350 (0.348–0.351) | 0.305 | 0.252 | **0.073** (4.8×) |
| same pass after `-g` churn (10% live) | 0.039 | 0.039 | 0.032 | 0.014 |

`bin-twxdur-full` (288,025 lines, 286,659 keys, ~1 sample each):

| metric | K1 today | K2 | K3 | K4 |
|---|---|---|---|---|
| write, ns/line | 11,302 (11,260–12,548) | 9,812 | 8,301 | **8,235** (−27%) |
| RSS after read | **1,134 MB** | 986 MB | 827 MB | **455 MB** |
| record store | 344 MB (1,200 B/key) | 180 MB | 180 MB | 180 MB (628 B/key) |
| counter store | 683 MB (2,383 B/key) | 606 MB | 432 MB | **139 MB (484 B/key)** |
| walk (eligibility only) | 0.341 | 0.037 | 0.034 | 0.034 |
| `-so p99` population pass | **22.9 s** | 22.4 s | 18.9 s | **2.15 s** (10.6×) |
| key column pass | — | 0.151 | 0.140 | 0.137 |
| churn (258k deletes + 2.9k injects) | 1.03 | 1.47 | 1.65 | 1.32 |
| population pass after churn | 2.56 | 2.51 | 2.12 | 0.27 |
| compaction | — | 0.39 | 0.44 | 0.49 |

100k slices scale the same way (twxdur-100k: RSS 397 → 154 MB, pass 7.8 → 0.76 s;
dpm-100k: pass 0.295 → 0.067 s).

### Surprises

- **The write side gets cheaper by a quarter** in every columnar arm — the composite
  key string (a second copy of the message text per line), the `bin_assign` /
  `partition_new` call shape and the two hash resolutions all sit on the per-line
  path today.
- K2 alone (drop the composite key, keep the entry shape) is worth −19% write and
  −13% RSS; the partition columns (K3) another −16% counter memory; the span-only
  bins (K4) are where the order-of-magnitude lives: the 265-slot dense array is
  summed once per quantile per key today.
- The synthetic high-cardinality case shows what #354 measured in the small: bin mode
  at 287k keys costs 1.13 GB where raw mode without durations costs 149 MB, and the
  population pass takes 23 s. The record store alone is 344 MB today because the
  sidecar fields double the per-message hash.
- Columnar churn is *slower* than the hash's here (1.3–1.6 vs 1.0 s): tombstoning
  writes `undef` into 26 columns per deleted row. A dead-row bitmap instead of
  per-column undef would remove that; not measured.
- Cross-validation: ltl's own run on the DPM log reports `MEMORY log_messages_counters
  9,652,179` and `population_walk 0.321`; K1 measures 9,652,290 B and 0.350 s.

### Findings and actions

- **Q7 answered: the counter store is keyed by row, as columns on the same store** —
  the composite key and the second store disappear, and with them the
  key-synchronisation invariant that `merge_log_message_entry_into_cluster` maintains
  today.
- **The bins representation is the lever**: span-only bins (K4) give 4.8–10.6× on
  the percentile pass and cut the counter store 2.5–4.9×, output-identical.
- `count_*` are hot columns when the count producer is active (every ScriptLog line
  carries `count=`); they are not a cold-hash case.

## V8 — Shared-grid fidelity (design proposal)

### Hypothesis

Every message today has its own bin grid (seeded on its first sample, doubled on
widening). Merging two messages — which `-g` grouping does at every fold — has to
re-project both histograms onto a union grid through the geometric-midpoint remap, an
approximation applied on top of the binning. A single log-spaced grid shared by the
whole store (bin index = `floor(bpd × log10(value))`, only occupied indices stored)
would make merges an exact index-wise add, remove all per-message grid state, and
never move an existing count. The question is whether it loses fidelity against the
exact percentiles.

### Method

`prototype/426-grid-fidelity.pl` on the DPM log (3,419 keys with positive
durations): for every key, exact nearest-rank percentiles (`$sorted[int($n*$q)]`, as
`calculate_statistics`) versus today's geometry (production subs verbatim) and the
shared grid, both at 53 bins/decade with the same within-bin exponential
interpolation; then the same for 1,655 merged pairs of keys (consecutive keys in
sorted order, both with ≥ 2 samples) — today via `merge_bin_counter_entries`, shared
via index-wise add. Errors are relative to the exact value; one bin width is 4.44%.

### Result

| scope | quantile | today | shared grid |
|---|---|---|---|
| per key | p95 median / p95 / max abs error; within one bin | 2.35% / 4.22% / **5.81%**; 98.8% | 1.70% / 4.25% / 4.44%; **100%** |
| per key | p99 | 2.37% / 4.16% / 4.44%; 100% | 1.89% / 4.28% / 4.44%; 100% |
| per key | p999 | 2.40% / 4.19% / 4.44%; 100% | 1.91% / 4.32% / 4.44%; 100% |
| merged pair | p95 | 1.69% / 4.72% / **12.3%**; 93.7% | 1.53% / 4.13% / 14.1%; **99.9%** |
| merged pair | p99 | 1.79% / 4.60% / **6.53%**; 94.5% | 1.99% / 4.30% / 4.44%; **100%** |
| merged pair | p999 | 1.83% / 4.60% / **6.53%**; 94.5% | 2.17% / 4.32% / 4.44%; **100%** |

Today's geometry performed 178 partition widenings across the keys, and 1,359 of the
1,655 merges (82%) needed a union remap. p50 (both scopes, both schemes) carries
large outliers — up to 98% — that are identical between the two geometries: they are
the rank convention (`int(n·q)` in the raw path vs `ceil(q·N)` in the bin path) on
keys with 2–4 samples, not a binning effect; the existing raw-vs-bin envelope already
absorbs them.

### Findings and actions

- **Per message the shared grid is at least as accurate as today's** (lower median
  error at every quantile; the same one-bin bound at p99/p999; today's widenings push
  p95 past a bin width, the shared grid does not).
- **After merging, the shared grid keeps the one-bin bound and today's does not** —
  the remap costs up to 1.5 bins at p99/p999 and 2.8 bins at p95.
- Adaptivity is preserved: the grid needs no range up front (an index exists for any
  positive value), a key's span grows on demand, and existing counts never move.
- This reopens #187 D5 (per-key seeded partitions with HdrHistogram doubling) and is
  the architect's decision; the measurements above are its input. Percentile values
  would shift by up to one bin width and the bin-mode baselines would be re-blessed
  once.
- **Scope of this validation versus #189's.** The primitives were validated under #189
  (`prototype/189-bin-counter-primitives.pl`,
  `prototype/189-bin-counter-primitives-validation-report.md`) across five aspects:
  accuracy against the `calculate_statistics` oracle, in-bin formula edge cases,
  seeding heuristic + overflow/underflow audit, per-key fan-out at scale, and `-V`
  output. This section covers only the first, on one log, for a geometry #189 never
  saw. V7's arms are digest-identical to production and inherit #189's validation;
  the shared grid does not, and must be taken through every #189 aspect before it
  can be adopted (`features/426-per-message-statistics-store.md` § Next step).

## Overall findings

1. **Q1 — the traversal case is real and larger than the ladder implied**: on the real
   as-built store, columnar is 5.7× (walk) and 10× (sort) faster than L0 and 3–4×
   faster than the ladder's fresh-hash floor.
2. **Q2 — write-side neutral** on the single-field path; −14%/line on the multi-field
   access path, which is aliasing (C) and comes with D for free.
3. **Q3 / Q12 — memory −24% RSS** at 287k keys (≈ 60% of the theoretical ceiling; D's
   own arrays are ≈ 80 B/key); columns exist per family/demand, nothing gated per line.
4. **Q4 — deletion**: tombstone + one 0.065 s compaction after the `-g` final pass;
   no dearer than hash deletes on a one-column store, and the compacted store is
   smaller than the hash's.
5. **Q10 — cheap arms do not suffice**: B is within noise of A at scale (it wins only
   where keys are not tied); C is a write-side gain only.
6. **Key column**: build after the read loop sharing the hash's key strings; the
   insert-time copy costs +31% RSS and slower sorts to save a 0.13 s pass.
7. On the measured construct the statistics phase drops from ≈ 0.54 s of traversal to
   ≈ 0.19 s (≈ 0.06 s without the key pass); ≈ 10–13% of the 2.7 s run. The read
   phase is unchanged on this file and ≈ 6% faster per line on access logs.
8. **Bin mode (V7)**: the counter store keyed by row as columns on the same store,
   with span-only bins, is output-identical and gives −25% per line on the read
   path, 2.5–4.9× less counter memory, and 4.8–10.6× on the `-so p99` population
   pass; at 287k keys with durations that is 1.13 GB → 455 MB and 23 s → 2.2 s.
9. **Shared grid (V8)**: at least as accurate per message as today's per-key
   partitions and strictly better after merges (one-bin bound kept, 100% vs 94.5%);
   a #187 D5 decision for the architect.
10. `count_*` is a hot column family, not a cold one, on ScriptLog data.

Not measured here, carried to implementation planning as design questions: Q5 (merge
surface — materialised row view vs rewrite), Q6 (F7's arbitrary key set — the lazy cold
hash handles it; not exercised), Q9 (measured only in the shape "category selects a
store handle in the branch that assigns `$category`"), Q11 (per-column `MEMORY`
attribution); a dead-row bitmap for tombstones (V7's churn cost).

## Artefacts

- `prototype/426-generate-fixtures.sh` — fixture dataset (`/tmp/ltl-426-fixtures/`).
- `prototype/426-store-mini.pl` — the arms; `prototype/426-run-matrix.sh` — driver
  with cross-arm parity; `prototype/426-pivot.pl` — results → tables.
- `prototype/426-asbuilt-probe.pl` + `prototype/426-asbuilt-run.sh` — the in-`ltl`
  probe (V1).
- `prototype/426-bin-store-mini.pl` — the `-mdm bin` arms (V7; run through the
  same driver with `MINI=prototype/426-bin-store-mini.pl`).
- `prototype/426-grid-fidelity.pl` — the shared-grid fidelity comparison (V8).
- `prototype/426-results/` — `results.tsv` / `parity.txt` (raw matrix),
  `bin-results.tsv` / `bin-parity.txt` (bin matrix), `asbuilt-100k.txt` /
  `asbuilt-full.txt` (probe runs), `grid-fidelity-dpm.md` / `.tsv` (V8).
