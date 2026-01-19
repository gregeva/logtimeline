# Heatmap Implementation: Decisions & Questions Requiring Input

This document captures the key decisions and questions that need input before implementing the heatmap feature in ltl, based on the prototype demonstrations and codebase analysis.

---

## 1. Rendering Approach

**Question:** Which rendering approach should be the default?

Run `perl prototype/heatmap-mini.pl` to compare:

| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| **1. Shade + Color** | `░▒▓█` + color gradient | Maximum info density | Can look busy; dithering on some terminals |
| **2. Color Only** | `█` with color intensity | Clean, modern; universal compatibility | Relies entirely on color; may be harder to distinguish adjacent levels |
| **3. Hybrid** | `░▓█` (3 shades) + color | Good balance | Slightly more complex |
| **4. Background Color** | Space with bg color | Smoothest appearance | May not stand out; some terminal quirks |

**Recommendation from spec:** Start with **Approach 2 (Color-Only)** as default.

**Decision needed:**
- [ ] Confirm default approach
- [ ] Should other approaches be available via command-line option (e.g., `--heatmap-style shade`)?

---

## 2. Histogram Bucket Boundaries

**Question:** Should bucket boundaries be logarithmic or linear?

| Metric | Recommendation | Rationale |
|--------|----------------|-----------|
| **Duration** | Logarithmic | Latency spans orders of magnitude (1ms to 100,000ms); log scale provides better resolution at low latencies where most traffic lives |
| **Bytes** | Linear or Log | Response sizes may span wide range; depends on use case |
| **Count** | Linear | Count distribution typically more uniform |

**Formula for logarithmic:**
```perl
$boundary[$i] = $min * ($max / $min) ** ($i / $num_buckets)
```

**Decision needed:**
- [ ] Confirm logarithmic for duration
- [ ] Choose approach for bytes: logarithmic or linear?
- [ ] Choose approach for count: linear or logarithmic?

---

## 3. Highlight Background Colors

**Question:** Which background color works best for highlighting?

Run `perl prototype/heatmap-mini.pl` and look at "HIGHLIGHT BACKGROUND COLOR OPTIONS" section.

The prototypes tested these combinations:

| Background | 256-Color Index | Visibility on Bright Yellow | Visibility on Dim Brown |
|------------|-----------------|---------------------------|------------------------|
| **Yellow** | 226 | Low contrast (same family) | Good contrast |
| **White** | 231 | Good contrast | Excellent contrast |
| **Cyan** | 51 | Excellent contrast | Good contrast |
| **Magenta** | 201 | Excellent contrast | Good contrast |
| **Orange** | 208 | Medium contrast | Medium contrast |
| **Green** | 46 | Good contrast | Good contrast |

**Observation from prototypes:**
- Cyan and Magenta provide the best contrast across ALL density levels (bright yellows AND dim browns)
- Yellow background on yellow foreground is hard to see
- White works well for dim areas but may be too stark

**Decision needed:**
- [ ] Which background color for duration metric highlights? (Recommend: Cyan or Magenta)
- [ ] Which background color for bytes metric highlights?
- [ ] Which background color for count metric highlights?
- [ ] Or should the user be able to configure this?

---

## 4. Color Gradient Definition

**Question:** How many color steps and which colors?

Current prototype uses 10-12 color steps:

**Duration (Yellow gradient):**
```perl
@yellow = (233, 234, 58, 94, 136, 142, 178, 184, 220, 226);
# dark gray → olive → brown → yellow → bright yellow
```

**Bytes (Green gradient):**
```perl
@green = (233, 234, 22, 28, 34, 40, 46, 82, 118, 154);
# dark gray → dark green → green → bright green
```

**Count (Cyan gradient):**
```perl
@cyan = (233, 234, 23, 29, 30, 36, 37, 43, 44, 51);
# dark gray → dark cyan → cyan → bright cyan
```

**Decision needed:**
- [ ] Are these color gradients acceptable?
- [ ] Should gradients be configurable or fixed?
- [ ] Do you need to test on different terminal emulators first?

---

## 5. Scale/Legend Display

**Question:** Should the heatmap include a scale indicator or legend?

**Options:**

A. **No legend** - Keep output minimal, rely on column heading
B. **Inline legend** - Show scale in the header row only
C. **Footer legend** - Add legend after the bar graph output
D. **Per-row markers** - Show P50/P95/P99 position markers on each row

**Example of inline legend (Option B):**
```
             │ duration heatmap: 0ms ──────────────────────── 5.0s
  ─────────┼────────────────────────────────────────────────────
  08:00:00 │ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
```

**Example of footer legend (Option C):**
```
  Density: █ few ████████ many requests
  Scale: 0ms ─────────── 500ms ─────────── 1s ─────────── 5s
```

**Decision needed:**
- [ ] Which legend approach?
- [ ] Should legend be optional (command-line flag)?

---

## 6. Integration with Existing Highlight

**Question:** How should heatmap interact with the existing `-highlight` option?

**Current ltl highlight behavior:**
- Appends `-HL` to category bucket names
- Uses background colors to differentiate highlighted rows
- Tracks separate totals for highlighted requests

**Proposed heatmap highlight behavior:**
- Track separate histogram: `%log_heatmap_hl{$bucket}{$range_index}`
- Cells with highlighted requests get bright background
- Foreground color (density) remains the same

**Decision needed:**
- [ ] Confirm the bright-background approach for heatmap highlights
- [ ] Should highlighted cells show ONLY the highlighted requests' density, or the total density with highlight overlay?

---

## 7. Heatmap Width

**Question:** Is 51 characters the right width for the heatmap?

**Current statistics column:** 56 characters
- Border: 3 chars (`│ ` + padding)
- P50: 11 chars
- P95: 11 chars
- P99: 11 chars
- P999: 11 chars
- CV: 7 chars
- Padding: 2 chars

**Proposed heatmap column:** 56 characters
- Border: 3 chars
- Heatmap cells: 51 chars
- Padding: 2 chars

**Consideration:** 51 histogram buckets may be more than needed. With logarithmic distribution, the resolution at high latencies may be too fine.

**Decision needed:**
- [ ] Is 51 buckets appropriate, or should it be fewer (e.g., 40, 30)?
- [ ] Should bucket count be configurable via command-line?

---

## 8. CSV Output Format

**Question:** How should heatmap data be included in CSV output (`-o` flag)?

**Options:**

A. **No heatmap in CSV** - Only output when rendering to terminal
B. **Histogram counts as columns** - Add 51 columns with bucket counts
C. **Histogram summary** - Add columns for non-empty bucket count, max density
D. **JSON blob** - Include histogram as JSON string in one column

**Decision needed:**
- [ ] Which CSV output approach?
- [ ] Should `-o` (CSV) and `-hm` (heatmap) be mutually exclusive?

---

## 9. Command-Line Interface

**Question:** What should the command-line interface look like?

**Proposed:**
```bash
./ltl --heatmap [metric] [options] logfile(s)
./ltl -hm [metric] [options] logfile(s)
```

**Metric options:**
- `duration` (default) - Latency distribution
- `bytes` - Response size distribution
- `count` - Request count distribution

**Examples:**
```bash
./ltl --heatmap logs/access.log              # duration heatmap
./ltl -hm bytes logs/access.log              # bytes heatmap
./ltl --heatmap -highlight "POST" logs/*.log # with highlight filter
```

**Additional options to consider:**
- `--heatmap-style [color|shade|hybrid|bg]` - Rendering approach
- `--heatmap-legend` - Show legend
- `--heatmap-width N` - Number of histogram buckets

**Decision needed:**
- [ ] Confirm basic `-hm`/`--heatmap` interface
- [ ] Should additional options be implemented in v1 or deferred?

---

## 10. Implementation Phases

**Question:** Should this be implemented in phases?

**Proposed phases:**

### Phase 1: Core Implementation
- Add `-hm`/`--heatmap` command-line option
- Implement histogram data collection during log processing
- Implement color-only rendering (Approach 2)
- Support duration metric only
- Basic highlight support

### Phase 2: Extended Features
- Add bytes and count metrics
- Add scale/legend display
- Add CSV output support
- Test on multiple platforms

### Phase 3: Polish
- Add configurable rendering styles
- Add configurable bucket count
- Performance optimization
- Documentation and examples

**Decision needed:**
- [ ] Confirm phased approach
- [ ] What's the priority order if not as proposed?

---

## 11. New Requirements / Feature Requests

**Question:** Are there any additional requirements not captured in the original specification?

Please list any new requirements or modifications to consider:

### Potential Additions (for discussion)

1. **Dark/Light terminal theme support**
   - Should colors adapt to terminal background color?
   - Or provide `--heatmap-theme dark|light` option?

2. **Percentile markers on heatmap**
   - Overlay P50/P95/P99 markers on the heatmap row?
   - Example: `████████│██│██░░░░░░░` (markers at percentile positions)

3. **Comparative mode**
   - Two heatmaps side-by-side (e.g., highlighted vs non-highlighted)?
   - Before/after comparison for different time ranges?

4. **Interactive mode**
   - Cursor navigation to inspect individual cells?
   - Zoom in/out on latency ranges?

5. **Aggregation options**
   - Show heatmap across ALL time buckets combined (single row summary)?
   - Rolling window heatmap?

6. **Export formats**
   - Export heatmap as image (PNG)?
   - Export as HTML with hover tooltips?

7. **Threshold alerts**
   - Highlight cells exceeding a count threshold?
   - Visual indicator when P99 exceeds a value?

8. **Custom bucket boundaries**
   - Allow user-defined bucket boundaries (e.g., `--heatmap-buckets 0,100,500,1000,5000`)?

9. **Metric normalization**
   - Normalize across rows (each row 0-100%)?
   - Or use global max (current approach)?

10. **Memory/performance considerations**
    - For very large log files, should histogram data be streamed or buffered?
    - Maximum number of time buckets to display?

### Your Additional Requirements

Please add any requirements specific to your use cases:

- [ ] _________________________________
- [ ] _________________________________
- [ ] _________________________________
- [ ] _________________________________

---

## Summary of Decisions Needed

| # | Decision | Options | Recommendation |
|---|----------|---------|----------------|
| 1 | Default rendering | Shade/Color/Hybrid/BG | Color-only |
| 2 | Duration buckets | Log/Linear | Logarithmic |
| 3 | Bytes buckets | Log/Linear | TBD |
| 4 | Count buckets | Log/Linear | Linear |
| 5 | Highlight bg color | Yellow/White/Cyan/Magenta | Cyan or Magenta |
| 6 | Legend display | None/Inline/Footer | TBD |
| 7 | Heatmap width | 51/40/30/configurable | 51 (match stats width) |
| 8 | CSV output | None/Columns/Summary/JSON | TBD |
| 9 | Phase 1 scope | Full/Core only | Core only |
| 10 | New requirements | See section 11 | TBD |

---

## Next Steps

1. Review this document and provide decisions
2. Run prototypes on your preferred terminal to validate color choices
3. Add any new requirements to section 11
4. Confirm implementation phases
5. Begin Phase 1 implementation

**To run prototypes:**
```bash
cd /Users/gregeva/Documents/GitHub/logtimeline
perl prototype/heatmap-mini.pl    # Compact comparison
perl prototype/heatmap-test.pl    # Full demonstration
```
