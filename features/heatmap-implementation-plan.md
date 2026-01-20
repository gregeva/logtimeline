# Heatmap Feature Implementation Plan

This document provides the detailed implementation plan for adding the heatmap visualization feature to ltl, based on decisions captured in `prototype/HEATMAP-DECISIONS.md`.

---

## Executive Summary

The heatmap feature adds a new visualization mode (`-hm`/`--heatmap`) that replaces the duration statistics column with a color-intensity histogram showing the distribution of metric values (duration, bytes, or count) across logarithmic buckets. Each row represents a time bucket, and each character position represents a value range, with color intensity indicating request density.

---

## Key Design Decisions (from HEATMAP-DECISIONS.md)

| Decision | Choice |
|----------|--------|
| Rendering approach | Color-only (Approach 2) - `█` with color intensity |
| Bucket boundaries | Logarithmic for all metrics (duration, bytes, count) |
| Base color | Matches metric column color (Yellow=2, Green=3, Cyan=4, Blue=5, Magenta=6) |
| Highlight overlay | Background color matches the metric's column color |
| Legend | Inline legend (Option B) - scale shown in header row |
| Heatmap width | Derived from `$durations_graph_width` minus border/padding (dynamic) |
| CSV output | No heatmap data in CSV |
| CLI interface | `-hm`, `-hm duration`, `-hm bytes`, `-hm count` |
| Empty cell background | NC/RESET (not black) - works on white or black terminals |
| Percentile markers | Optional command-line feature (future) |

---

## Phase 1: Planning (This Document)

### 1.1 New Data Structures

Add to GLOBALS section (~line 85):

```perl
# Heatmap data structures
my $heatmap_enabled = 0;                    # Flag: heatmap mode active
my $heatmap_metric = 'duration';            # Metric: duration|bytes|count
my %heatmap_data;                           # {$bucket}{$range_index} = count
my %heatmap_data_hl;                        # {$bucket}{$range_index} = highlighted count
my %heatmap_raw;                            # {$bucket} = [raw values] - temporary
my %heatmap_raw_hl;                         # {$bucket} = [highlighted raw values] - temporary
my @heatmap_boundaries;                     # Pre-calculated bucket boundaries
my ($heatmap_min, $heatmap_max) = (0, 0);   # Global min/max for normalization
my $heatmap_max_density = 0;                # Maximum density across all cells
```

**Note:** Heatmap width is NOT a separate variable. It is dynamically calculated from `$durations_graph_width`:

```perl
# Heatmap width = $durations_graph_width - border(3: "│ " + " ") - padding
# Current: $durations_graph_width = $graph_column_padding_latency + 52 + $graph_column_padding_all
# So heatmap character count = 52 (the content area)
```

### 1.2 Color Gradient Definitions

Add color gradients for each metric base color. These use 256-color ANSI codes progressing from dark/dim to bright:

```perl
# Heatmap color gradients (10 steps from dim to bright)
# Index 0 = lowest density (dim), Index 9 = highest density (bright)
my %heatmap_colors = (
    'yellow' => [233, 234, 58, 94, 136, 142, 178, 184, 220, 226],   # Duration (column 2)
    'green'  => [233, 234, 22, 28, 34, 40, 46, 82, 118, 154],       # Bytes (column 3)
    'cyan'   => [233, 234, 23, 29, 30, 36, 37, 43, 44, 51],         # Count (column 4)
    'blue'   => [233, 234, 17, 18, 19, 20, 21, 27, 33, 39],         # Future metrics (column 5)
    'magenta'=> [233, 234, 53, 89, 125, 127, 163, 165, 201, 207],   # Future metrics (column 6)
);

# Map metric names to column numbers and colors
my %heatmap_metric_column = (
    'duration' => { column => 2, color => 'yellow' },
    'bytes'    => { column => 3, color => 'green' },
    'count'    => { column => 4, color => 'cyan' },
);
```

### 1.3 Command-Line Options

Add to `adapt_to_command_line_options()` (~line 456):

```perl
'heatmap|hm:s' => \$heatmap_metric,   # Optional value, defaults to 'duration'
```

Add validation after GetOptions:

```perl
# Heatmap option processing
if (defined $heatmap_metric) {
    $heatmap_enabled = 1;
    $heatmap_metric = 'duration' if $heatmap_metric eq '';  # Default when -hm used without value
    die print_usage("invalid heatmap metric")
        unless grep { $_ eq $heatmap_metric } qw(duration bytes count);
}
```

### 1.4 Histogram Data Collection

Modify `read_and_process_logs()` (~line 1062-1084) to collect heatmap data:

```perl
# After existing duration/bytes/count capture, add:
if ($heatmap_enabled) {
    my $value;
    if ($heatmap_metric eq 'duration' && defined $duration) {
        $value = $duration;
    } elsif ($heatmap_metric eq 'bytes' && defined $bytes) {
        $value = $bytes;
    } elsif ($heatmap_metric eq 'count' && defined $count) {
        $value = $count;
    }

    if (defined $value && $value >= 0) {
        # Track global min/max for boundary calculation
        $heatmap_min = $value if $heatmap_min == 0 || $value < $heatmap_min;
        $heatmap_max = $value if $value > $heatmap_max;

        # Store raw values for later bucketing (after min/max known)
        push @{$heatmap_raw{$bucket}}, $value;
        push @{$heatmap_raw_hl{$bucket}}, $value if $category_bucket =~ /-HL$/;
    }
}
```

### 1.5 Histogram Bucketing (Post-Processing)

Add new subroutine `calculate_heatmap_buckets()` to be called after `read_and_process_logs()`:

```perl
sub calculate_heatmap_buckets {
    return unless $heatmap_enabled && $heatmap_max > $heatmap_min;

    # Calculate heatmap width from $durations_graph_width
    # $durations_graph_width = $graph_column_padding_latency + 52 + $graph_column_padding_all
    # Content width = 52 (minus border "│ " which is handled in rendering)
    my $heatmap_bucket_count = $durations_graph_width - $graph_column_padding_latency - $graph_column_padding_all;

    # Calculate logarithmic bucket boundaries
    # Formula: boundary[i] = min * (max/min)^(i/num_buckets)
    my $ratio = $heatmap_max / ($heatmap_min || 1);
    for my $i (0 .. $heatmap_bucket_count) {
        $heatmap_boundaries[$i] = $heatmap_min * ($ratio ** ($i / $heatmap_bucket_count));
    }

    # Distribute raw values into histogram buckets
    foreach my $bucket (keys %heatmap_raw) {
        foreach my $value (@{$heatmap_raw{$bucket}}) {
            my $range_index = find_heatmap_bucket($value, $heatmap_bucket_count);
            $heatmap_data{$bucket}{$range_index}++;

            # Track max density for color normalization
            $heatmap_max_density = $heatmap_data{$bucket}{$range_index}
                if $heatmap_data{$bucket}{$range_index} > $heatmap_max_density;
        }

        # Process highlighted values
        if (exists $heatmap_raw_hl{$bucket}) {
            foreach my $value (@{$heatmap_raw_hl{$bucket}}) {
                my $range_index = find_heatmap_bucket($value, $heatmap_bucket_count);
                $heatmap_data_hl{$bucket}{$range_index}++;
            }
        }

        # Free memory
        delete $heatmap_raw{$bucket};
        delete $heatmap_raw_hl{$bucket};
    }
}

sub find_heatmap_bucket {
    my ($value, $bucket_count) = @_;
    for my $i (0 .. $#heatmap_boundaries - 1) {
        return $i if $value >= $heatmap_boundaries[$i] && $value < $heatmap_boundaries[$i + 1];
    }
    return $bucket_count - 1;  # Last bucket catches max values
}
```

### 1.6 Heatmap Rendering

Add new subroutine `print_heatmap_row()` to replace duration statistics when heatmap is enabled:

```perl
sub print_heatmap_row {
    my ($bucket, $printed_chars) = @_;

    # Calculate heatmap content width from $durations_graph_width
    my $heatmap_content_width = $durations_graph_width - $graph_column_padding_latency - $graph_column_padding_all;

    my $missing_chars = $terminal_width - $printed_chars - $durations_graph_width;
    print " " x $missing_chars if $missing_chars > 0;
    print "$colors{'bright-black'}│$colors{'NC'} ";

    my $color_key = $heatmap_metric_column{$heatmap_metric}{color};
    my @gradient = @{$heatmap_colors{$color_key}};
    my $highlight_bg = get_highlight_bg_color($heatmap_metric);

    for my $i (0 .. $heatmap_content_width - 1) {
        my $density = $heatmap_data{$bucket}{$i} // 0;
        my $density_hl = $heatmap_data_hl{$bucket}{$i} // 0;

        if ($density == 0) {
            # Empty cell - use NC/RESET (no background color)
            print " ";
        } else {
            # Calculate color index based on density (logarithmic scaling)
            my $color_index = 0;
            if ($heatmap_max_density > 1) {
                $color_index = int(log($density) / log($heatmap_max_density) * 9);
                $color_index = 9 if $color_index > 9;
                $color_index = 0 if $color_index < 0;
            }

            my $fg_color = $gradient[$color_index];

            if ($density_hl > 0 && defined $highlight_regex) {
                # Highlighted cell: use metric's column color as background
                print "\033[48;5;${highlight_bg}m\033[38;5;${fg_color}m█\033[0m";
            } else {
                # Normal cell: foreground color only, no background
                print "\033[38;5;${fg_color}m█\033[0m";
            }
        }
    }
    print " ";
}

sub get_highlight_bg_color {
    my ($metric) = @_;
    # Return the bright version of the metric's column color for highlighting
    my %highlight_colors = (
        'duration' => 226,  # Bright yellow
        'bytes'    => 46,   # Bright green
        'count'    => 51,   # Bright cyan
    );
    return $highlight_colors{$metric} // 226;
}
```

### 1.7 Inline Legend (Header Row)

Add legend printing before the bar graph output:

```perl
sub print_heatmap_legend {
    my $metric = $heatmap_metric;
    my $min_str = format_heatmap_value($heatmap_min, $metric);
    my $max_str = format_heatmap_value($heatmap_max, $metric);

    # Calculate heatmap content width from $durations_graph_width
    my $heatmap_content_width = $durations_graph_width - $graph_column_padding_latency - $graph_column_padding_all;

    my $label_width = length($min_str) + length($max_str) + 4;  # "min ──── max"
    my $line_width = $heatmap_content_width - $label_width;
    my $line = "─" x ($line_width > 0 ? $line_width : 1);

    # Position legend to align with heatmap column
    my $legend_offset = $terminal_width - $durations_graph_width;
    my $legend = sprintf("%s%s│ %s heatmap: %s %s %s",
        " " x $legend_offset,
        $colors{'bright-black'},
        $metric,
        $min_str,
        $line,
        $max_str
    );

    print "$legend$colors{'NC'}\n";
}

sub format_heatmap_value {
    my ($value, $metric) = @_;
    if ($metric eq 'duration') {
        return format_time($value, 'ms');
    } elsif ($metric eq 'bytes') {
        return format_bytes($value);
    } else {
        return $value;
    }
}
```

### 1.8 Integration Points in print_bar_graph()

Modify `print_bar_graph()` (~line 2029-2049):

```perl
# Replace:
# DURATION STATISTICS print duration statistics table
if( $print_durations && !$omit_durations && !$omit_stats ) {

# With:
if ($heatmap_enabled) {
    print_heatmap_row($bucket, $printed_chars);
} elsif ($print_durations && !$omit_durations && !$omit_stats) {
    # Existing duration statistics code...
}
```

Add legend printing before the main loop:

```perl
# Before: foreach my $bucket ( sort { $a <=> $b } keys %log_stats ) {
if ($heatmap_enabled) {
    print_heatmap_legend();
}
```

### 1.9 Width Calculation

The heatmap width is derived from the existing `$durations_graph_width` variable, which is already calculated in `normalize_data_for_output()` at line 1536:

```perl
$durations_graph_width = $print_durations && !$omit_durations && !$omit_stats
    ? $graph_column_padding_latency + 52 + $graph_column_padding_all
    : 0;
```

When heatmap is enabled, we need to ensure `$durations_graph_width` is set even if duration stats would otherwise be omitted:

```perl
# Add after existing calculation:
if ($heatmap_enabled && $durations_graph_width == 0) {
    # Force allocation of space for heatmap column
    $durations_graph_width = $graph_column_padding_latency + 52 + $graph_column_padding_all;
}
```

The actual heatmap content width is then:
```perl
my $heatmap_content_width = $durations_graph_width - $graph_column_padding_latency - $graph_column_padding_all;
# Currently = 52 characters
```

---

## Phase 2: Scheduling

### Implementation Order

1. **Global variables** - Add heatmap data structures and color definitions
2. **Command-line parsing** - Add `-hm` option and validation
3. **Data collection** - Modify `read_and_process_logs()` to capture raw values
4. **Width handling** - Ensure `$durations_graph_width` is set when heatmap enabled
5. **Bucketing logic** - Add `calculate_heatmap_buckets()` subroutine
6. **Rendering** - Add `print_heatmap_row()` and `print_heatmap_legend()`
7. **Integration** - Modify `print_bar_graph()` to use heatmap when enabled

### File Changes

All changes are in a single file: `ltl`

| Section | Lines (approx) | Changes |
|---------|----------------|---------|
| GLOBALS | 85-150 | Add heatmap variables and color definitions |
| Command-line | 453-494 | Add `-hm` option parsing |
| read_and_process_logs | 1020-1085 | Add heatmap raw data capture |
| normalize_data_for_output | 1535-1540 | Ensure width set for heatmap mode |
| New subroutines | After 1112 | Add `calculate_heatmap_buckets()`, `find_heatmap_bucket()` |
| New subroutines | After 1800 | Add `print_heatmap_row()`, `print_heatmap_legend()`, `format_heatmap_value()`, `get_highlight_bg_color()` |
| print_bar_graph | 2029-2049 | Add conditional heatmap rendering |
| MAIN | 2500+ | Add call to `calculate_heatmap_buckets()` |

---

## Phase 3: Implementation

### 3.1 Implementation Steps

1. Add global variables (heatmap data structures, colors)
2. Add command-line option `-hm`/`--heatmap`
3. Add raw value capture in log processing loop
4. Ensure `$durations_graph_width` is set when heatmap enabled
5. Add `calculate_heatmap_buckets()` and `find_heatmap_bucket()` functions
6. Add rendering functions (`print_heatmap_row`, `print_heatmap_legend`)
7. Integrate into `print_bar_graph()`
8. Add call to bucketing function in MAIN section

### 3.2 Code Quality Checklist

- [ ] No new Perl module dependencies
- [ ] Works on both Unix and Windows
- [ ] Respects existing `-omit-*` flags where applicable
- [ ] Memory-efficient (free raw data after bucketing)
- [ ] Handles edge cases (no data, single value, all same value)
- [ ] Heatmap width strictly derived from `$durations_graph_width`

---

## Phase 4: Testing

### Test Cases

| Test | Command | Expected Result |
|------|---------|-----------------|
| Basic duration heatmap | `./ltl -hm logs/access.log` | Yellow-gradient heatmap in place of stats |
| Explicit duration | `./ltl -hm duration logs/access.log` | Same as above |
| Bytes heatmap | `./ltl -hm bytes logs/access.log` | Green-gradient heatmap |
| Count heatmap | `./ltl -hm count logs/access.log` | Cyan-gradient heatmap |
| With highlight | `./ltl -hm -h "POST" logs/access.log` | Heatmap with highlighted cells |
| Invalid metric | `./ltl -hm invalid logs/access.log` | Error message |
| No duration data | `./ltl -hm logs/application.log` | Graceful handling |
| Multiple files | `./ltl -hm logs/*.log` | Combined heatmap |
| With filters | `./ltl -hm -dmin 100 logs/access.log` | Filtered heatmap |

### Visual Verification

1. Run `perl prototype/heatmap-mini.pl` and compare output
2. Verify color gradients match prototype
3. Verify highlight background colors work on both light and dark terminals
4. Verify empty cells have no background (NC/RESET)
5. Verify legend shows correct min/max values
6. Verify heatmap width matches `$durations_graph_width` content area exactly

---

## Phase 5: Validation

### Acceptance Criteria

1. **Functional**
   - `-hm` with no argument defaults to duration
   - `-hm duration`, `-hm bytes`, `-hm count` all work
   - Highlight overlay uses correct background color
   - Empty cells have transparent background
   - Legend shows correct scale

2. **Visual**
   - Color gradient progresses from dim to bright
   - Heatmap width derived from `$durations_graph_width` (not hardcoded)
   - Works on dark and light terminal backgrounds

3. **Performance**
   - No significant memory increase for typical log files
   - No noticeable slowdown in processing

4. **Compatibility**
   - Works with existing flags (`-b`, `-n`, `-include`, etc.)
   - CSV output (`-o`) works (heatmap data not included)

---

## Phase 6: Documentation

### Updates Required

1. **ltl script**
   - Update version number (line 75)
   - Update TO-DO comments (line 5) to mark heatmap as complete
   - Update `print_usage()` with new options

2. **README.md**
   - Add heatmap section with examples
   - Add screenshot of heatmap output

3. **features/heatmap.md**
   - Update implementation status
   - Document any deviations from original spec

4. **CLAUDE.md**
   - Add `%heatmap_data` to key data structures
   - Add `-hm` to key options list

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Memory usage with large files | Stream raw values, bucket incrementally, free after processing |
| Terminal compatibility | Use 256-color codes (widely supported), test on multiple terminals |
| Edge case: all same values | Handle log(0) and log(1) cases in bucket calculation |
| Integration conflicts | Heatmap replaces stats column; mutually exclusive display |

---

## Future Enhancements (Not in Scope)

Per HEATMAP-DECISIONS.md, these are deferred:

- Percentile markers as command-line option
- Configurable heatmap width
- Alternative rendering styles (shade, hybrid)
- Heatmap data in CSV output
