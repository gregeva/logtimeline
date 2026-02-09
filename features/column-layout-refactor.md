# Column Layout Refactor — Requirements

**GitHub Issue:** #33
**Status:** Planning
**Blocks:** #26 (session metric column)
**Fixes:** #27 (array mismatch bug)

## Problem Statement

### Evolutionary History

ltl's bar graph output started as a simple 3-column layout: timestamp, legend, and occurrences. Over time it grew to support up to 9 visible columns (timestamp, legend, occurrences, duration, bytes, count, threadpool activity, user-defined metrics, and latency/heatmap), plus vertical separators and conditional visibility. Each addition was bolted on incrementally, resulting in today's fragile system.

### Current State

The layout is managed through 5 overlapping data structures populated piecemeal across ~170 lines of code in `normalize_data_for_output()`:

1. **`%graph_width`** — Hash with 1-indexed keys (1–6). Only covers the "middle" graph columns (occurrences through UDMs). Does not include timestamp, legend, or latency/heatmap.
2. **`@printed_column_widths`** — 0-indexed array covering ALL visible columns. Built up incrementally with separate `push` statements scattered across the setup code.
3. **`@printed_column_names`** — 0-indexed array of header labels. Built separately from widths — can get out of sync.
4. **`@printed_column_spacing`** — 0-indexed array of inter-column padding. Built in parallel with widths but in separate statements.
5. **`$graph_count`** vs **`$graph_column_count`** — Two variables with similar purpose but different computation. `$graph_count` starts at 1 (line 88), incremented per column with data. `$graph_column_count` starts at 1, incremented before its check.

Additionally, graph column widths are distributed using hardcoded percentage tables (65/35 for 2 columns, 62/21/17 for 3, etc.) that don't scale gracefully.

### Why This Is a Problem

- **Fragile**: Adding a column requires updating multiple arrays in sync across distant code locations. Missing one causes bugs (see #27).
- **Inconsistent indexing**: `%graph_width` is 1-indexed; the `@printed_*` arrays are 0-indexed with offsets for timestamp/legend. This mapping is error-prone.
- **Hardcoded scaling**: The percentage tables must be manually authored for each column count (2–6). Adding a 7th column type requires a new table.
- **No visibility model**: Hiding a column (e.g., occurrences via `-ov`) is handled through ad-hoc conditionals rather than a coherent visibility system. Some combinations can't be toggled at all.
- **Brittle rendering**: `$printed_chars` tracks cumulative characters printed per row to calculate remaining space. Any rendering change risks breaking alignment.
- **Color coupling**: Colors are assigned by array position, not by column identity. The ordering works today because `@graph_columns` priority ensures known metrics land in predictable positions, but the mapping is implicit and fragile.

This accumulated debt blocks issue #26 (adding a session metric column), which would require yet another column type threaded through all these structures.

## Goals

1. **Single source of truth** — One data structure defines each column's name, type, width, spacing, visibility, color, and rendering behavior.
2. **Algorithmic width distribution** — Replace hardcoded percentage tables with an algorithm that distributes proportional space based on column count and priority.
3. **First-class visibility** — Each column carries a visible/hidden flag. Hiding a column triggers automatic space redistribution. No ad-hoc conditionals.
4. **Fill-to-width rendering** — Each column's renderer fills its exact allocated width (padding included). Eliminates `$printed_chars` tracking entirely.
5. **Compound column support** — Legend (and potentially others) can be modeled as a group of sub-columns with a spanning header.
6. **Separators as layout elements** — Vertical separators (`│`) are distinct elements in the layout, not embedded in column padding.
7. **Stable color identity** — Color is a property of the column definition, not derived from position at render time.
8. **Unblock #26** — The refactored system must make adding a new column type (session metric) straightforward.

## Non-Goals

- **New visual features** — This refactor preserves existing output exactly. No new columns, metrics, or display modes.
- **Configuration file** — Column layout is not user-configurable beyond existing CLI options.
- **Column reordering** — Columns remain in their current fixed order. User-configurable ordering is out of scope.
- **Per-column scaling** — Scaling bars to local max vs global max is a rendering concern noted for future work, not part of this refactor.
- **Perl OO / classes** — The solution should use Perl data structures (hashes, arrays), not a class hierarchy. Keep it idiomatic with the rest of the codebase.

## Column Types

Each column in the layout has a **sizing type** that determines how its width is calculated:

### Fixed Width
Width is constant, determined by format or configuration. Not affected by terminal width changes (beyond minimum terminal width requirements).

- **Timestamp**: Width derived from `$output_timestamp_format` plus optional millisecond precision (+4 chars).
- **Latency statistics**: Fixed at 52 characters.
- **Heatmap**: Default 52 characters, user-configurable via `-hmw`.

### Content-Driven Width
Width is determined by scanning the actual data to find the maximum content width.

- **Legend**: Width is the maximum across all time buckets of the combined category counts and rates text.

### Proportional Width
Width is a share of the remaining terminal space after fixed and content-driven columns are allocated. Shares are distributed algorithmically based on priority.

- **Occurrences**: Default primary/focus column — receives the largest share.
- **Duration, Bytes, Count**: Secondary metric columns — receive equal smaller shares.
- **Threadpool activity columns**: Secondary.
- **User-defined metric columns**: Secondary.

### Separator
A fixed-width (1 character) vertical line (`│`) that visually divides column groups. Modeled as a distinct layout element, not as padding on adjacent columns.

### ~~Compound Column~~ (Removed)
~~A logical grouping of sub-columns that share a single spanning header.~~

**Decision (2026-02-09):** The compound sub-column model for legend was dropped during prototyping. The legend column works well precisely because the boundary between category counts and message rates floats per row. A rigid sub-column model would force fixed widths for counts and rates independently, making legend wider than necessary — the worst-case counts width plus worst-case rates width rarely occur on the same row. Legend remains a single content-driven column with a floating internal boundary.

## Layout Engine Requirements

### Width Allocation Algorithm

The layout engine must allocate terminal width in this order:

1. **Separators**: Each consumes 1 character.
2. **Fixed columns**: Timestamp, latency/heatmap — consume their predetermined widths.
3. **Content-driven columns**: Legend — consumes its data-determined width.
4. **Spacing**: Inter-column padding for all allocated columns.
5. **Proportional columns**: Remaining width is distributed among visible graph columns.

### Proportional Distribution

Replace the hardcoded percentage tables with an algorithmic approach:

- One column is designated as the **focus** (primary) column. Default: occurrences.
- The focus column receives a larger share of proportional space.
- Remaining proportional columns split the rest equally.
- The algorithm must work for any number of proportional columns (1–6+), not just the current 2–6 range.
- **Min/max constraints**: The focus column should not dominate on very wide terminals or starve on narrow ones. Beyond a threshold, extra width flows to secondary columns.

### Visibility Toggling

- Each column has a `visible` flag.
- When a column is hidden, its width (and any adjacent separator) is returned to the proportional pool.
- Hiding/showing a column triggers redistribution — no manual recalculation required.
- This enables toggling occurrences visibility, which is not cleanly possible today.

### Rounding

The existing `cumulative_round_widths()` function handles sub-pixel rounding to ensure column widths sum exactly to terminal width. This behavior must be preserved.

## Header System Requirements

### Individual Headers
Each visible column gets a header label centered within its allocated width. This is the current behavior for graph columns (occurrences, duration, bytes, etc.).

### Spanning Headers
A compound column's header spans the combined width of all its visible sub-columns. The header text is centered across the full span.

- **Legend**: The header "legend" spans the counts sub-column, the conditional spacing sub-column, and the rates sub-column.

### Separator Headers
Separators display a `│` character in the header row, consistent with data rows.

### Header/Footer Alignment
The header underline (`─`) and any footer elements (e.g., heatmap scale with `┴`) must align precisely with column boundaries. This is currently correct and must be preserved.

## Separator Requirements

- Separators are **distinct layout elements** in the column array, not padding embedded in adjacent columns.
- Current separator positions: (1) between legend and occurrences, (2) between the last graph column and latency/heatmap.
- **Adjacency rule**: A separator is only visible if both adjacent columns (or column groups) are visible.
- Separator width is always 1 character.

## Color Scheme Requirements

### Current System
Colors are assigned by position in parallel arrays (line 3439–3448):
- Position 1 → yellow, Position 2 → green, Position 3 → cyan, Position 4 → blue, Position 5 → magenta.
- Each color has: a name, plain background value, highlight background value, and an 8-step gradient array.
- Known metrics (duration, bytes, count) have stable positions because `@graph_columns` priority controls column ordering.
- User-defined metrics get colors assigned by their position among the remaining slots.

### Requirements
- Color identity should be carried as a **property of the column definition**, not looked up by position at render time.
- Known metrics retain their established colors (duration=yellow, bytes=green, count=cyan).
- UDM columns continue to receive colors from the available palette based on their position among UDM columns.
- Heatmap colors must remain consistent with their metric's graph column color.
- See issue #64 for consolidation of hardcoded color references (separate from this refactor, but the column definition approach enables it).

## Legend Column Requirements

The legend column contains heterogeneous sub-content (category counts and message rates) but is modeled as a **single content-driven column** with a floating internal boundary.

### Width Calculation
- Legend width = maximum total legend text width across all time buckets (counts + internal spacing + rates combined).
- This preserves the current `$legend_length` calculation where the boundary between counts and rates floats per row, keeping overall legend width as compact as possible.

### Internal Layout (per row)
- Category counts are rendered left-aligned within the legend width.
- Message rates are rendered right-aligned within the legend width.
- A 2-character gap separates them, but this gap floats — it is not a fixed sub-column boundary.
- One row may have long counts and short rates; another may have short counts and long rates. Both fit within the same total width.

### Visibility
- Counts and rates each respect their own omit flags (`-ov`, `-or`).
- When one is hidden, the other expands to fill the legend width.

## Rendering Requirements

### Fill-to-Width
Each column's renderer is responsible for filling its exact allocated width:
- Bar graphs render the bar and pad the remainder with spaces.
- Text columns render content and pad to fill.
- The gap between the last bar character and the next column boundary becomes whitespace **within** the column, not between columns.

### Eliminate $printed_chars
With fill-to-width rendering, the cumulative `$printed_chars` tracking (currently ~15 updates per row in `print_bar_graph`) becomes unnecessary. Each column fills its width independently; the row is complete when all columns have rendered.

### Preserve Output
The rendered output must be **pixel-identical** to the current output for all existing option combinations. This is a hard constraint — any visual difference is a bug.

## Data Structure Integration

The layout engine does not exist in isolation — it must integrate with ltl's existing data structures and access patterns. The rendering code is tightly coupled to how data is stored and keyed. This refactor must work within those realities, not against them.  

### Current Data Flow

Columns get their data from two primary structures:

- **`%log_occurrences{$bucket}{$category}{occurrences}`** — Used by the legend column (category counts/rates) and the occurrences bar graph (scaled_occurrences per category). Three-level nesting.
- **`%log_stats{$bucket}{$key}`** — Used by all other graph columns (duration, bytes, count, UDMs, threadpools) and latency statistics. Two-level nesting with `scaled_*` and `*-HL` key variants.

### Calculate Table Before Scaling Data

The table layout MUST be calculated prior to the data scaling, as the data will be scaled proportionately into the available space.  To support this, the scaling logic must have access to the metrics column size to define its allowed chart width.

Table column spacing layout calculations must be done after data has been read in `read_and_process_log`and before it is scaled in `normalize_data_for_output` which will calculated the scaled values to fit into the applicable columns.

### Integration Constraint

The refactored layout system must work with these existing data structures. It should not require restructuring `%log_occurrences` or `%log_stats` — those are upstream concerns. However, the column definitions should make the data access pattern for each column explicit (which structure, which keys) rather than leaving it implicit in scattered rendering code.

### Context: Data Structure Friction (Future Follow-Up)

Two data structure inconsistencies create friction but are outside the scope of this layout refactor. They are noted here for awareness during design and as candidates for future work:

1. **Inconsistent data sources** — The occurrences column is the only metric column that reads from `%log_occurrences` instead of `%log_stats`. All other metrics use `%log_stats{$bucket}{scaled_$key}`. This forces a completely different rendering path for occurrences (category loop with per-category colored blocks vs. single scaled value).

2. **Occurrences scaling anomaly** — Most metrics have their scaling calculated and stored as `scaled_*` keys in `%log_stats` during `normalize_data_for_output()`. Occurrences scaling happens separately, stored in `%log_occurrences{$bucket}{$category}{scaled_occurrences}`. There is no centralized scaling phase.

## Identified Problem Areas

The following data structure and rendering problems were identified during investigation. They are related to the column layout refactor and should be considered during design and prototyping. Each represents a friction point that the layout engine will need to accommodate or that may warrant its own refactoring effort as part of the broader output coherence work.

### 1. Positional Column Identity

**Problem**: Column identity is determined by array index position, not by name. `@printed_column_names` stores display labels only — they are never used as identifiers to look up data, colors, or rendering behavior. The color mapping in `print_bar_graph` (lines 4036-4058) uses a hardcoded if/elsif chain on `$column_number`:

```
if( $column_number == 2 ) { ... yellow ... }
elsif( $column_number == 3 ) { ... green ... }
```

This means column ordering implicitly determines color. Any reordering would silently change colors for all subsequent columns.

**Impact on refactor**: The layout engine should establish column identity through explicit identifiers, making position a derived property of the layout rather than the source of identity.

### 2. Scattered Scaling Logic

**Problem**: Metric scaling (converting raw values to bar widths) is spread across `normalize_data_for_output()` with different paths for different column types. Most metrics get `scaled_*` keys written into `%log_stats` (line 3403), but occurrences scaling happens in a separate code path storing results in `%log_occurrences` (line 3425). There is no centralized scaling phase.

**Impact on refactor**: The layout engine will need to accommodate multiple scaling patterns. A future refactoring could centralize scaling, but this layout refactor should not depend on it.

### 3. Conditional Rendering Cascade

**Problem**: The graph column rendering code (lines 3984-4058) is a long if/elsif chain that dispatches on metric type:

- `$key =~ /^(time|duration)$/i` → `format_time()`
- `$key =~ /^bytes$/i` → `format_bytes()`
- `$key =~ /^count$/i` → special count handling
- `$key =~ /^udm_(.+)$/` → config lookup + unit_type formatting

Each type has its own formatting logic, color selection, and value display. Adding a new metric type requires extending this cascade in multiple places.

**Impact on refactor**: The layout engine's column definitions could carry a formatting/rendering callback or type identifier, enabling dispatch by column definition rather than by regex on the key name. This would make the rendering path extensible without modifying the cascade.

### 4. Cumulative Character Tracking (`$printed_chars`)

**Problem**: The rendering code in `print_bar_graph` maintains a running `$printed_chars` counter with ~15 increments per row (lines 3858-4100). Each rendering code path must manually track how many characters it printed. The counter is used to calculate remaining space before the latency/heatmap column (line 4100: `$missing_chars = $terminal_width - $printed_chars - $durations_graph_width`).

This exists because columns don't self-report their rendered width — there's no "render into exactly N characters" abstraction. Any rendering change risks breaking alignment for all subsequent columns.

**Impact on refactor**: The fill-to-width rendering model (Goal #4) directly eliminates this. Each column renders into its exact allocated width. This is a primary deliverable of the refactor.

### 5. Column Selection Scatter (`@populated_graph_columns`)

**Problem**: The logic that determines which graph columns are visible is scattered across `normalize_data_for_output()`:

- `@graph_columns` (line 92) defines the available metric types
- `@populated_graph_columns` (line 3250) is the runtime subset — only metrics with data (`$max_total{$key} > 0`)
- Count column removal when terminal is too narrow (lines 3237-3243) happens separately
- `@graph_columns` is still used for iteration elsewhere despite `@populated_graph_columns` being the authoritative visible set

**Impact on refactor**: The layout engine's visibility system should consolidate column selection into a single phase. A column is visible or not; the reasons (no data, terminal too narrow, user flag) should all resolve to the same visibility flag.

## Testing Strategy

### Test Matrix
All column combinations must produce identical output before and after refactor:
- Basic: timestamp + legend + occurrences + latency
- With duration, bytes, count (individually and combined)
- With threadpool activity summary (`-tpas`)
- With user-defined metrics
- With heatmap (`-hm duration`, `-hm bytes`, `-hm count`)
- With omit flags (`-ov`, `-or`, `-os`) individually and combined
- With millisecond precision (`-ms`)
- At multiple terminal widths (60, 100, 160, 200, 350+)

### Regression Capture
Before refactoring, capture reference output for each test case. After refactoring, diff against reference. Any difference fails the test.

### Validation
Add a debug/assertion mode that verifies:
- All column widths sum to terminal width (including spacing and separators).
- No column has negative or zero width.
- Column arrays are consistent in length.

## Risks and Constraints

1. **Output regression** — The biggest risk. Mitigated by capture-and-diff testing across all option combinations.
2. **Scope creep** — The refactor touches core rendering. Discipline required to change structure without changing behavior.
3. **Legend complexity** — The legend sub-column decomposition is the most intricate part. May need prototyping to validate.
4. **Proportional algorithm tuning** — The hardcoded percentages produce specific visual results users are accustomed to. The algorithm must approximate these proportions, not just be mathematically clean.
5. **Cumulative rounding** — The existing `cumulative_round_widths()` function must integrate with the new layout engine. Edge cases around rounding with separators need attention.
6. **Large refactor surface** — The column setup, header printing, and row rendering code are all intertwined. Phased migration (coexisting old and new paths) may be necessary to keep the codebase working throughout.

## Relationship to Other Issues

- **#26 (Session metric column)**: Blocked by this refactor. Adding a new column type should be a matter of defining it in the layout system, not threading it through 5 data structures.
- **#27 (Array mismatch bug with `-tpa`)**: Root cause is the fragmented column management this refactor eliminates.
- **#64 (Color consolidation)**: The column-carries-its-color approach enables future cleanup of hardcoded color references, but #64 is a separate effort.

## Prototype Decisions & Learnings

*Captured from `prototype/column-layout-prototype.pl` — 2026-02-08*

### Algorithm Selection: Linear Decay

The linear decay algorithm was selected over exponential decay for proportional distribution:

```
focus_share = max(focus_min, focus_base - (N-2) * focus_step)
```

With parameters `focus_base=70, focus_step=10, focus_min=25`:

| N | Current | Algorithm | Max Delta |
|---|---------|-----------|-----------|
| 2 | 65/35 | 70/30 | 5pp |
| 3 | 62/21/17 | 60/20/20 | 3pp |
| 4 | 50/18/16/16 | 50/16.7/16.7/16.7 | 1.3pp |
| 5 | 40/15/15/15/15 | 40/15/15/15/15 | 0pp (exact) |
| 6 | 30/14/14/14/14/14 | 30/14/14/14/14/14 | 0pp (exact) |

The maximum deviation is 5 percentage points (at N=2), which is within acceptable visual tolerance. The algorithm is exact for N=4-6 and smoothly extends to N=7+ without requiring new hardcoded tables.

The formula uses `(N-2)` not `(N-1)` because the step applies starting from the 3rd column (N=2 is the anchor point where `focus_base` applies directly).

The exponential decay algorithm (`focus = max * decay^(N-2)`) was prototyped but rejected — it diverges more at N=3-5 where the current tables are well-established.

### Separator Modeling Validated

Modeling separators as distinct 1-character columns with `spacing=0` produces identical character budgets to the current approach where separators are embedded in padding:

- **Current**: `pad_count=2` includes the `│` as its first character. `pad_latency=3` includes `│` + 2 spaces via gap-fill.
- **New**: `sep_legend_graph` is a 1-char column; `occurrences.spacing` drops from 2 to 1. `sep_graph_stats` is a 1-char column; `latency.spacing` drops from 3 to 2. Net character budget: identical.

This was validated by the separator budget validation test (Section F) across all terminal widths.

### Width Allocation Pipeline

The 8-step allocation pipeline works correctly:

1. Resolve separator visibility (adjacency rule)
2. Allocate fixed columns (timestamp, latency)
3. Allocate separators (1 char each)
4. Allocate content-driven columns (legend)
5. Sum all spacing
6. Calculate remaining width
7. Distribute proportional via linear decay algorithm
8. Apply cumulative rounding (verbatim from ltl)

The cumulative rounding function integrates cleanly — it operates only on the proportional column widths array, not the full column set. Separators and fixed columns are excluded from rounding.

### Narrow Terminal Handling

At narrow widths (80-100 chars), the fixed columns (timestamp + legend + latency) can consume all available space, leaving nothing for proportional columns. This is a real constraint that ltl already handles by:
- Not showing latency stats when no duration data exists
- Dropping count columns when space is insufficient (ltl:3238)

The layout engine correctly calculates negative remaining space in these cases. The implementation must either hide latency/legend at narrow widths or allow minimum-width proportional columns with graceful degradation.

### Visibility Toggle Redistribution

The prototype validates that hiding columns correctly redistributes space:
- Hiding legend: its 30-char width flows to proportional columns
- Hiding latency + separator: 57 chars flow to proportional columns
- Separator adjacency rule: separators auto-hide when an adjacent column is hidden

This confirms the first-class visibility model works as designed.

### Dynamic Column Insertion

The `add_dynamic_column()` pattern (insert before `sep_graph_stats`) works cleanly for threadpool and UDM columns. New columns inherit the standard secondary spacing and get colors from the palette by index. No changes to the layout engine are needed — the engine is column-count agnostic.

### Key Decision: Spacing Model (Before/After)

Each column carries explicit `spacing_before` and `spacing_after` values rather than a single combined spacing. Spacing is anchored on separators and non-optional elements to avoid double-spacing when optional columns are hidden.

| Column | Before | After | Rationale |
|--------|--------|-------|-----------|
| timestamp | 0 | 0 | First column, no padding needed |
| legend | 1 | 0 | Space from timestamp; separator handles the other side |
| sep_legend_graph | 1 | 1 | Anchors spacing — always-present element between groups |
| occurrences | 0 | 1 | Separator's after handles the left side |
| duration/bytes/count | 1 | 1 | Standard inter-column spacing |
| sep_graph_stats | 0 | 0 | Latency's before handles both spaces |
| latency | 2 | 0 | Last column, no trailing padding |

**Key insight:** When legend is hidden, `timestamp(0/0)` + `sep(1/1)` + `occurrences(0/1)` gives exactly 1 space on each side of the separator. When legend is visible, `timestamp(0/0)` + `legend(1/0)` + `sep(1/1)` + `occurrences(0/1)` gives 1 space between timestamp and legend, then 1 space between legend and separator, then 1 space between separator and occurrences. No double-spacing in either case.

The prototype uses `‹` for before-spacing and `›` for after-spacing to make ownership visually unambiguous in mockup output.

### Key Decision: Legend as Single Content-Driven Column

The compound sub-column model for legend (counts + spacing + rates as separate sub-columns) was dropped. The legend works well because the boundary between counts and rates floats per row — one row may have long counts with short rates, the next the reverse. A rigid sub-column split would force worst-case widths for both, making the legend wider than necessary. Legend remains `type => 'content'` with a single width calculated from max total legend length.

### Integration Lesson: Content Trailing Spaces vs Layout Spacing

In the current ltl code, content strings for legend counts and rates include trailing spaces — e.g., `"WARN: 42 "` and `"12:892/m "`. These trailing spaces currently serve as inter-column padding because the old layout system doesn't have explicit column spacing.

In the new layout engine, spacing between columns is handled by `spacing_before` and `spacing_after` on each column definition. **Content strings must have trailing padding truncated before rendering into their column.** If not truncated, the trailing content spaces and the layout engine's spacing would double-count, pushing subsequent columns out of alignment.

The inter-category spaces within counts (e.g., the space between `"WARN: 42"` and `"ERROR: 3"`) are content separators and must be preserved — only the final trailing space needs stripping. During integration, the code that builds legend content strings will need to either: (a) stop appending trailing spaces, or (b) `rstrip` the final string before passing it to the layout engine.

### Integration Constraint: Legend Width Must Be Calculated Before Table Layout

The layout engine needs the legend column width to calculate the table, and the table must be calculated before `normalize_data_for_output` scales data to fit proportional columns. However, the legend width determination currently lives *inside* `normalize_data_for_output` (ltl:3133-3192), interleaved with the same loop that builds `$legend_length` as a running max across all time buckets.

**Current ordering in ltl:**
1. `read_and_process_logs()` — captures raw data
2. `calculate_all_statistics()` — computes stats
3. `normalize_data_for_output()` — determines `$legend_length` AND scales data to column widths

**Required ordering for the new layout engine:**
1. `read_and_process_logs()` — captures raw data
2. `calculate_all_statistics()` — computes stats
3. **Determine legend width** — scan all buckets for max `(counts + 2 + rates)` length
4. **Calculate table layout** — needs legend width, produces proportional column widths
5. **Scale data** — uses proportional column widths from step 4

The legend width calculation (step 3) must be extracted from `normalize_data_for_output` and run before the table layout. This is a code restructuring requirement — the current function does both steps 3 and 5 in a single pass.

**Performance consideration:** Rather than adding a separate pass over all buckets, the legend width could be calculated incrementally during `read_and_process_logs` as data is captured. Each time a bucket's categories or rates change, update a running max. This would avoid the extra iteration at the cost of maintaining the running max during data capture. The prototype demonstrates this by calculating legend width from sample data before passing it to `build_default_columns`.
