# Issue #269 — Output Ordering Audit

Branch: `269-output-ordering-non-deterministic` (off `release/0.15.0`)

## Scope

Systematic review of every `keys %hash` call site and every custom-comparator
`sort { ... }` block in `ltl`. Each site is classified as:

- **OUTPUT** — iteration order is observable in some user-visible output
  channel (stdout bar graph, summary table, `-o` CSV files, `-V` sections,
  error messages). These require a fix.
- **INTERNAL** — order does not reach output (accumulation into a hash by
  key, scalar `keys` for count, cardinality test, validation-only).

Classification criteria for INTERNAL:
- `scalar keys %h` — count only.
- `for my $k (keys %h) { $h2{$k} = ... }` — accumulation by key; output is
  driven by a later sorted iteration.
- `for my $k (keys %h) { $h{$k}{x} = scalar keys %{$h{$k}{y}} }` — same
  cardinality regardless of iteration order.
- `keys %h` followed immediately by a `sort` that already has a
  deterministic tiebreaker.
- Iteration whose only side effect is `delete` of the same keys.

## Findings — sites that MUST be fixed

### F1. `ltl:8462` — top-N message ranking (primary site cited in issue)

```perl
@sorted_log_keys = sort {
    my $occurrences_a = $log_messages{$category}{$a}{$sort_key} // 0;
    my $occurrences_b = $log_messages{$category}{$b}{$sort_key} // 0;
    if( $sort_ascending ) {
        $occurrences_a <=> $occurrences_b;
    } else {
        $occurrences_b <=> $occurrences_a;
    }
} keys %{$log_messages{$category}};
@top_keys = @sorted_log_keys[0 .. min($#sorted_log_keys, $top_n_messages - 1)];
```

**Output channel:** STATS CSV, MESSAGES CSV, summary table — top-N
selection. Ties on `$sort_key` lose to randomized `keys` ordering.
**Fix:** add `|| ($a cmp $b)` tiebreaker on the log key.

### F2. `ltl:8475` — statistical-metric sort path

```perl
} else {
    # Sort by statistical metric which first needs to be calculated for all messages
    @top_keys = keys %{$log_messages{$category}}
}
```

**Output channel:** same as F1, triggered when `-so` is one of
`min/mean/max/std_dev/cv/iqr/skewness/kurtosis/bimodality_coef/p1..p99999`.
No sort at all → fully randomized.
**Fix:** replace with `@top_keys = sort keys %{$log_messages{$category}};`
The downstream statistic-based slicing happens after this, but the
deterministic order ensures ties at that later step are also deterministic.

### F3. `ltl:8457` — outer category iteration over `%log_messages`

```perl
foreach my $category (keys %log_messages) {
```

**Output channel:** indirect. `%log_messages` has keys `plain` and
`highlight`; both are processed and written into `%log_messages{$category}`.
With only two categories the tied set is bounded, but the order in which
they are processed determines which category's statistics are computed
first. Stats are stored back into `%log_messages{$cat}{$key}{...}` keyed
by `$cat`+`$key`, so the final values are order-independent — but if any
shared side effect existed (none observed today), it would matter.

**Classification:** INTERNAL today, but a 2-key hash is trivially cheap
to sort. **Fix:** add `sort` for defensive determinism and consistency
with F8 / F9 below. Recommend `sort keys %log_messages`.

### F4. `ltl:10982` — message-table display sort (summary table render)

```perl
my @sorted_keys = sort {
    my $occurrences_a = $log_messages{$grouping}{$a}{$sort_key} // 0;
    my $occurrences_b = $log_messages{$grouping}{$b}{$sort_key} // 0;
    if( $sort_ascending ) {
        $occurrences_a <=> $occurrences_b;
    } else {
        $occurrences_b <=> $occurrences_a;
    }
} keys %{$log_messages{$grouping}};
```

**Output channel:** stdout summary table — message rows printed under
"TOP HIGHLIGHTED MESSAGES" / "TOP OVERALL MESSAGES". Same root cause as
F1: ties resolved by hash iteration order.
**Fix:** add `|| ($a cmp $b)` tiebreaker.

### F5. `ltl:11234` — threadpool-table display sort

```perl
my @sorted_keys = sort {
    my $occurrences_a = scalar keys %{$threadpool_activity{$grouping}{$a}} // 0;
    my $occurrences_b = scalar keys %{$threadpool_activity{$grouping}{$b}} // 0;
    if( $sort_ascending ) {
        $occurrences_a <=> $occurrences_b;
    } else {
        $occurrences_b <=> $occurrences_a;
    }
} keys %{$threadpool_activity{$grouping}};
```

**Output channel:** stdout "TOP HIGHLIGHTED THREAD POOLS" /
"TOP OVERALL THREAD POOLS" table. Ties on active-thread count lose to
randomized order.
**Fix:** add `|| ($a cmp $b)` tiebreaker.

### F6. `ltl:8563` — threadpool ordering for graph columns

```perl
@ordered_threadpools = sort { $threadpools{$b}{occurrences} <=> $threadpools{$a}{occurrences} } keys %threadpools;
```

**Output channel:** `@graph_threadpools_activity` derived from this order
becomes the threadpool column order in the bar graph and in CSV output
columns. Ties on `occurrences` → column ordering randomized.
**Fix:** add `|| ($a cmp $b)` tiebreaker on threadpool name.

### F7. `ltl:4579` — discriminative trigram selection (consolidation)

```perl
my @disc_trigrams = sort { ($ps->{$a} // 0) <=> ($ps->{$b} // 0) }
                    grep { exists $consolidation_ngram_index{$cat_gk}{$_} }
                    keys %$source_trigrams;
my $topk_actual = min($consolidation_discriminative_topk, scalar @disc_trigrams);
splice(@disc_trigrams, $topk_actual) if @disc_trigrams > $topk_actual;
```

**Output channel:** indirect but real. With `-g`, the top-K most
discriminative trigrams drive candidate selection in
`find_consolidation_candidates`. Trigrams with equal posting-list size
are very common; the splice keeps an arbitrary subset on ties. Different
trigrams → different candidate hit sets → different Dice scores → different
consolidation merges → different `%log_messages` keys → different MESSAGES
CSV rows.
**Fix:** add `|| ($a cmp $b)` tiebreaker on the trigram itself.

### F8. `ltl:4299` — final-pass S2/S5 capture

```perl
for my $cat_gk (keys %consolidation_unmatched) {
    my ($category_part) = split(/\|/, $cat_gk, 2);
    my ($s2, $s5) = (0, 0);
    for my $key (keys %{$consolidation_unmatched{$cat_gk}}) {
        ...
    }
}
```

**Output channel:** values are summed per `$cat_gk` and stored in
`$consolidation_cat_stats{$cat_gk}{streaming_s2/s5}`. The sum is
commutative — order does not affect the totals. **Classification:**
INTERNAL.

### F9. `ltl:11415` — verbose unmatched-key partition for S2/S5

```perl
for my $key (keys %{$consolidation_unmatched{$cat_gk} // {}}) {
    my $occ = $log_messages{$category_part}{$key}{occurrences} // 1;
    if ($occ >= $consolidation_occurrence_ceiling) { $ceiling_filtered++; } else { $genuinely_unmatched++; }
}
```

**Output channel:** counters used in `-V` consolidation verbose section.
Sum is commutative — order-independent. **Classification:** INTERNAL.

### F10. `ltl:4081` — CSV separator auto-detection

```perl
my ($best_sep) = sort { $sep_counts{$b} <=> $sep_counts{$a} } keys %sep_counts;
```

**Output channel:** indirect (input parsing). On a tie between candidate
separators (extremely unlikely on real CSV headers) the picked separator
is randomized. If two real CSV headers ever tie, the resulting parse
would change between runs. **Classification:** OUTPUT (edge case but
deterministic fix is cheap).
**Fix:** add `|| ($a cmp $b)` tiebreaker. Prefer comma on ties for
human predictability — `cmp` lex-orders `","` < `";"` < `"\t"` so comma
wins, which is the conventional default.

## Findings — sites that do NOT need fixing (INTERNAL)

| Site | Pattern | Why safe |
|------|---------|----------|
| `ltl:650` | `foreach my $key (keys %colors)` | Adds `${key}-HL` keys to same hash; final hash content order-independent |
| `ltl:857` | `scalar keys %$store` | Count only |
| `ltl:872` | `sort { $a <=> $b } @rebins` | Sort of array, deterministic on values |
| `ltl:1208` | `my @tiers = keys %tier_seen` | Used only for cardinality test (`@tiers != 1`) |
| `ltl:1479` | `sort { length($b) <=> length($a) } @parts` | Sort of getopt aliases; ties = same length, picks any longest |
| `ltl:1618, 1696` | `sort keys %...` | Already sorted |
| `ltl:3944-3945` | `map { lc($_) => $_ } keys %...` | Hash construction by key |
| `ltl:4302` | `for my $key (keys %{$consolidation_unmatched{$cat_gk}})` | Commutative accumulation (see F8) |
| `ltl:4333, 4409, 4410, 4435, 4438` | `sort keys %...` | Already sorted |
| `ltl:4335` | `sort { ... cmp ... } keys %...` | Sort comparator already uses `cmp` — deterministic |
| `ltl:4514-4515, 4520, 4524` | Dice coefficient body | `scalar keys` + set membership; result independent of iteration order |
| `ltl:4550, 4557, 4558` | `keys %$trigrams`, `keys %{$consolidation_ngram_index{$cat_gk}}` | Index build — accumulation by key |
| `ltl:4589` | `for my $cand_key (keys %{$consolidation_ngram_index{$cat_gk}{$trig}})` | Accumulates into `%candidate_hits` by key; later sorted at 4621 |
| `ltl:4602` | `for my $cand_key (keys %candidate_hits)` | Filters into `@results`; sorted at 4621 with `|| ($a cmp $b)` |
| `ltl:4621` | `sort { $b->{score} <=> $a->{score} || $a->{key} cmp $b->{key} }` | Already has tiebreaker |
| `ltl:4951` | `for my $ck (keys %consolidation_unmatched)` (checkpoint trigger) | Triggers checkpoints on filtered subset — each checkpoint has its own deterministic sort at 5478; trigger order does not change which keys participate |
| `ltl:5369` | `for my $key (keys %consumed)` | `delete` from `%log_messages` — same final set |
| `ltl:5478` | `sort keys %{$consolidation_unmatched{$cat_gk}}` | Already sorted |
| `ltl:5532, 5533` | `scalar keys`, `delete` loop | Count + same-set delete |
| `ltl:5651` | `for my $struct (keys %current_sizes)` | Per-struct HWM update by key — order-independent |
| `ltl:6552` | `for my $metric (keys %histogram_metrics)` | Validation only; dies on error, no order-sensitive output |
| `ltl:6610` | `foreach my $key (keys %filter_range)` | 2-key hash (start/end); processed independently into `$filter_range{$key}` |
| `ltl:6983` | `scalar keys %csv_col_index` | Count only |
| `ltl:7612` | `for my $cat_gk (sort keys %consolidation_unmatched)` | Already sorted |
| `ltl:7613` | `scalar keys %{...}` | Count for threshold test |
| `ltl:7672, 7751, 7795` | `foreach my $bucket (keys %heatmap_...)` | Per-bucket value computation written to `$heatmap_data{$bucket}{...}` — order-independent; `$heatmap_max_density` is max-reduction (commutative) |
| `ltl:7674, 7905, 7972, 8633` | `sort { $a <=> $b } @array` | Numeric sort of array values — deterministic |
| `ltl:8314, 9824` | `sort { $a <=> $b } keys %log_analysis/%log_occurrences` | Already sorted numerically by bucket epoch |
| `ltl:8457` | `keys %log_messages` (categories) | See F3 — recommend defensive fix |
| `ltl:8555, 8557, 8572-8579, 8593-8597` | `keys %{$threadpool_activity/log_sessions/...}` | Accumulation/cardinality writes by key |
| `ltl:9120, 9125, 9152, 9162, 9169, 9172, 9314, 9339` | `keys %log_occurrences`, `keys %{$log_occurrences{$bucket}}` | All are max-reduction or per-key write-back; output ordering controlled by separate `@log_levels` array iteration and the `sort` at 9824 |
| `ltl:9745` | `sort keys %memory_high_water_marks` | Already sorted |
| `ltl:9766` | `for my $cat (keys %log_messages)` | Sum-only into `$log_messages_entries` |
| `ltl:9768, 9769` | `scalar keys` | Counts only |
| `ltl:10619` | `sort { $a->{sort_order} <=> $b->{sort_order} } @selected` | `sort_order` is assigned uniquely upstream — deterministic by construction |
| `ltl:10851` | `sort { $memory_high_water_marks{$b} <=> $memory_high_water_marks{$a} } grep ... keys %memory_high_water_marks` | **POTENTIAL ISSUE**: ties on size resolve via hash order. Memory HWM display in summary table (`-mem`). See F11 below |
| `ltl:10853` | `keys %memory_high_water_marks` (inside above grep) | Resolved with the same sort fix |
| `ltl:10960, 11226` | `foreach my $column (keys %col_relative_size)` | Width-assignment by key |
| `ltl:11235-11242` | Threadpool display sort | Same as F5 — addressed there |
| `ltl:11312` | `scalar keys %{$threadpool_activity{$grouping}{$key}}` | Count only |
| `ltl:11389` | `for my $cat_gk (keys %consolidation_patterns)` | Sum-only into `$total_patterns_all` |
| `ltl:11393` | `sort keys %consolidation_cat_stats` | Already sorted |
| `ltl:11516` | `scalar keys %consolidation_cat_stats` | Count for conditional print |

## Additional finding flagged during audit

### F11. `ltl:10851` — memory HWM display sort (`-mem`)

```perl
my @sorted = sort { $memory_high_water_marks{$b} <=> $memory_high_water_marks{$a} }
             grep { $memory_high_water_marks{$_} >= $min_size_threshold }
             keys %memory_high_water_marks;
```

**Output channel:** `-mem` summary table — rows listing per-structure
memory high-water marks. Ties on size (rare but possible for small empty
structures) resolve via hash order.
**Fix:** add `|| ($a cmp $b)` tiebreaker on structure name.

## Summary

**Sites requiring fixes:** 8

| # | Line | Site | Output channel |
|---|------|------|----------------|
| F1 | 8462 | top-N message ranking | MESSAGES CSV, STATS CSV, summary table |
| F2 | 8475 | statistic-metric sort fallback | same as F1 |
| F4 | 10982 | message-table display sort | summary table |
| F5 | 11234 | threadpool-table display sort | summary table |
| F6 | 8563 | threadpool column ordering | bar graph + CSV columns |
| F7 | 4579 | discriminative trigram pick (`-g`) | indirect via consolidation → MESSAGES CSV |
| F10 | 4081 | CSV separator auto-detect | input parsing edge case |
| F11 | 10851 | `-mem` HWM display sort | `-mem` summary table |

**Defensive (recommended) fixes:** 1

| # | Line | Site | Rationale |
|---|------|------|-----------|
| F3 | 8457 | outer category iteration in stats calc | 2-key hash; cheap `sort` for consistency with F8/F9 |

**Sites confirmed safe:** all remaining `keys %` and `sort` occurrences
listed in the INTERNAL table above.

## Proposed fix pattern

Standard tiebreaker is `|| ($a cmp $b)` after the primary comparison.
For sites that sort by hash value (F1, F4, F5, F6, F10, F11), the
tiebreaker compares the hash key.
For F2, the bare `keys` is replaced with `sort keys`.
For F7, the tiebreaker compares the trigram string.

## Verification plan (executed after fixes land)

Per issue acceptance criteria:

1. Two back-to-back `ltl … -o <file>` invocations on the same input
   produce byte-identical MESSAGES CSV and STATS CSV. Test scenarios:
   - Default ranking (occurrences)
   - `-g 90` consolidated
   - `-so p999` percentile-sorted
   - `-so std_dev` statistic-sorted
   - `-hm` heatmap mode
   - `-hg` histogram mode
2. Issue #224 Phase H test 1 (fresh-baseline pass) succeeds without the
   `--ignore-row-key-mismatch` workaround flag.
