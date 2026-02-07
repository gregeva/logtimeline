# Column Layout Refactor

**GitHub Issue:** #33
**Status:** Planning

## Overview

Refactor the column width and layout management into a unified data structure to eliminate bugs caused by array mismatches.

## Current Column Layout System (Technical Reference)

The bar graph output uses a sophisticated column layout system with spacing and padding. Understanding this is critical for alignment and for implementing the refactor.

### Key Width Variables

- `$terminal_width` - Total terminal width (e.g., 120)
- `$timestamp_length` - Width allocated for timestamp column
- `$legend_length` - Width allocated for legend column (log level counts)
- `$max_graph_width` - Space for all bar graph columns (calculated as `$terminal_width - $legend_length - $timestamp_length - $durations_graph_width`)
- `$durations_graph_width` - Width for heatmap/statistics column (= `$graph_column_padding_latency + $heatmap_width + $graph_column_padding_all`)
- `%graph_width` - Hash mapping column numbers to their allocated widths

### Padding Constants (line ~90)

- `$graph_column_padding_all = 1` - Trailing padding after all columns
- `$graph_column_padding_timestamp = 1` - Padding for timestamp column
- `$graph_column_padding_legend = 0` - Padding for legend column
- `$graph_column_padding_count = 2` - Padding for count column (includes `│` separator)
- `$graph_column_padding_other = 1` - Padding for other metric columns
- `$graph_column_padding_latency = 3` - Padding before heatmap/latency column

### Column Separator Behavior

- The `│` character is used as a column separator
- For the heatmap column: `│` (1 char) + space (1 char padding) + content (`$heatmap_width` chars) + trailing space (1 char)
- The `$printed_chars` variable tracks how many characters have been printed on the current line
- Missing padding is calculated as: `$terminal_width - $printed_chars - $durations_graph_width`

### Heatmap Column Structure

When heatmap is enabled, the heatmap column replaces the latency statistics column:
- Separator: `│` (1 char)
- Padding: ` ` (1 space)
- Content: heatmap data or scale values (`$heatmap_width` chars, default 52)
- Trailing: ` ` (1 space)

### Footer Alignment

The footer scale must align with the heatmap data rows:
- Footer uses `┴` at the same position as the data row's `│`
- Scale content starts after one padding character (like the space after `│`)
- Scale labels at 0% position should left-align with first heatmap column
- Scale labels at 100% position should right-align with last heatmap column

### Boundary Array Indexing

For a heatmap with N display columns (default 52):
- `@heatmap_boundaries` has N+1 elements (indices 0 through N)
- `boundaries[0]` = minimum value
- `boundaries[N]` = maximum value
- Display column i covers range `[boundaries[i], boundaries[i+1])`
- To get the value at 100% position, use `boundaries[N]`, NOT `boundaries[N-1]`

## Problem Statement

The current code uses multiple overlapping data structures with inconsistent indexing:

1. **`%graph_width`** (hash, 1-indexed keys 1-6) - Only covers "middle" bar graph columns
2. **`@printed_column_widths`** (array, 0-indexed) - Covers ALL printed columns
3. **`@printed_column_names`** (array, 0-indexed) - Column names for headers
4. **`@printed_column_spacing`** (array, 0-indexed) - Spacing/padding after each column
5. **`$graph_count`** vs **`$graph_column_count`** - Similar purpose but computed differently

This causes bugs when adding new columns (e.g., issue #27) because arrays can get out of sync.

## Proposed Solution

See GitHub issue #33 for detailed options. Recommended approach (Option C):

1. Create a single `add_column()` subroutine that always adds to all three arrays together
2. Replace all `push @printed_column_*` statements with calls to `add_column()`
3. Consolidate `$graph_count` and `$graph_column_count` into one variable
4. Add validation that array lengths match before using them

## Affected Code Sections

Key areas that would need updating (approximate line numbers):
- Lines 2004-2017: timestamp, legend, occurrences column setup
- Lines 2033-2046: graph column name additions
- Lines 2117-2123: graph column width/spacing additions
- Lines 2126-2138: latency/heatmap column additions
- Lines 2540-2576: column header printing
- Lines 2580-2800: row printing loops

## Testing Strategy

1. Test all column combinations:
   - Basic (timestamp + legend + occurrences + latency)
   - With duration/bytes
   - With threadpool activity (`-tpa`)
   - With heatmap (`-hm`)
   - With omit flags (`-ov`, `-or`, `-os`)

2. Verify output formatting matches current behavior exactly

## Related Issues

- #27 - Bug caused by array mismatch when using `-tpa`
