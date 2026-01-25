# Feature Requirements: Duration Unit Autodetection

## Branch
`feature/duration-unit-autodetection`

## GitHub Issue
[#17 - Command line option to specify input timestamp units](https://github.com/gregeva/logtimeline/issues/17)

## Overview
Add automatic detection of duration/timing units (nanoseconds, microseconds, milliseconds, seconds) from log files, with conversion to milliseconds for internal processing. Include a command-line override option for cases where autodetection fails.

## Background / Problem Statement

### Current Limitation
LogTimeLine assumes all duration values are in **milliseconds**. This fails for:
- **Nginx**: Uses seconds with millisecond precision (e.g., `0.250` = 250ms)
- **Apache HTTP Server**: Uses microseconds with `%D` directive (e.g., `250000` = 250ms)
- **Tomcat 10.1+**: Changed `%D` from milliseconds to microseconds

### Industry Variations

| Server | Directive | Unit | Example (250ms) |
|--------|-----------|------|-----------------|
| Nginx | `$request_time` | seconds (decimal) | `0.250` |
| Apache HTTP Server | `%D` | microseconds | `250000` |
| Apache HTTP Server | `%{ms}T` | milliseconds | `250` |
| Tomcat 6-9 | `%D` | milliseconds | `250` |
| Tomcat 10.1+ | `%D` | microseconds | `250000` |
| Tomcat (all) | `%T` | seconds (decimal) | `0.250` |
| JBoss EAP 7 | `%D` | milliseconds | `250` |
| ThingWorx | `durationMS=` | milliseconds | `250` |
| CodeBeamer | `[Xms]` | milliseconds | `[250ms]` |

**Key Insight**: The same `%D` directive means different units across servers and versions.

### References
- [Apache mod_log_config](https://httpd.apache.org/docs/current/mod/mod_log_config.html)
- [Tomcat AccessLogValve](https://tomcat.apache.org/tomcat-9.0-doc/config/valve.html)
- [Nginx ngx_http_log_module](https://nginx.org/en/docs/http/ngx_http_log_module.html)
- [Tomcat 10.1 %D microseconds change](https://medium.com/@beroza07/after-migrating-from-tomcat-8-to-tomcat-11-you-might-notice-something-alarming-in-your-access-8f2960a25d90)

## Goals
1. Automatically detect duration units from log files based on value analysis
2. Convert all durations to milliseconds (floating-point precision) for internal processing
3. Provide command-line override for manual unit specification
4. Display detected unit on progress line during file processing
5. Warn users when autodetection may be incorrect
6. Support per-file unit detection for mixed-source analysis

## Requirements

### Functional Requirements

#### 1. Supported Duration Units

| Unit | CLI Value | Conversion to ms |
|------|-----------|------------------|
| Nanoseconds | `ns` | / 1,000,000 |
| Microseconds | `us` | / 1,000 |
| Milliseconds | `ms` | x 1 (no conversion) |
| Seconds | `s` | x 1,000 |

#### 2. Command Line Interface

**New Option:**
```
-du <unit>    Specify duration unit (ns, us, ms, s)
--duration-unit <unit>
```

**Behavior:**
- When specified, disables autodetection for all files
- Invalid values produce error: `Invalid duration unit 'X'. Valid values: ns, us, ms, s`

**Examples:**
```bash
./ltl --duration-unit us logs/apache_access.log    # Apache microseconds
./ltl -du s logs/nginx_access.log                  # Nginx seconds
./ltl logs/mixed/*.log                             # Autodetect per file
```

#### 3. Autodetection Algorithm

**Look-Ahead Buffering Approach:**

When the first duration value is encountered in a file:
1. Read ahead ~1000 additional lines into a buffer
2. Extract all duration values from these lines
3. Analyze the population to detect the unit
4. Push buffered lines back to be processed normally
5. Apply detected unit to all durations in this file

**Detection Heuristics (applied in order):**

1. **Pattern Hints** (highest priority):
   - `durationMS=` or `durationMs=` in log format -> milliseconds
   - `[Xms]` pattern (CodeBeamer format) -> milliseconds
   - `[X.XXXs]` pattern -> seconds

2. **Decimal Detection**:
   - Values contain decimal point AND integer part is small (0-10) -> seconds
   - Example: `0.250`, `1.5`, `3.142` -> seconds

3. **Statistical Analysis**:
   - Median value > 100,000 AND max > 1,000,000 -> microseconds
   - Median value > 100,000,000 -> nanoseconds

4. **Default**: milliseconds

**Challenges:**
- API calls range from <1ms to 10+ seconds, making ranges overlap
- A 10-second call (10000ms) looks like 10000us (10ms)
- Cannot rely solely on magnitude

#### 4. Progress Line Display

Update the existing progress line (line ~970) to include detected unit:

**Current format:**
```
Processing line 15000 in file logs/access.log (15000 overall)
```

**New format:**
```
Processing line 15000 in file logs/access.log (15000 overall) [unit: ms]
```

Or when detection just occurred:
```
Processing line 1000 in file logs/access.log (1000 overall) [unit: us autodetected]
```

The unit indicator should appear after autodetection is complete for that file.

#### 5. Runtime Validation and Warnings

Since autodetection may be wrong and conversions cannot be retroactively fixed:

**Validation Rules:**
- If detected as **seconds** but values > 1000 frequently seen -> suspect wrong (1000s = 16+ min)
- If detected as **milliseconds** but values > 100,000 frequently seen -> might be microseconds
- If detected as **microseconds** but many values < 100 -> might be milliseconds

**Warning Output (yellow):**
```
WARNING: Duration unit autodetection may be incorrect for file 'access.log'.
  Detected: milliseconds, but seeing values suggesting microseconds.
  Consider using -du us to specify the unit manually.
```

#### 6. Verbose Output Section (`-V` / `--verbose`)

Add a new section to verbose output showing detection details per file:

```
Duration Unit Detection:
  logs/apache_access.log:
    Detected unit: microseconds
    Method: statistical analysis (median: 125000, max: 5200000)
    Sample values: 125000, 250000, 89000, 1500000, 45000
  logs/nginx_access.log:
    Detected unit: seconds
    Method: decimal detection (values contain decimal, int part 0-10)
    Sample values: 0.125, 0.250, 0.089, 1.500, 0.045
  logs/thingworx/ScriptLog.log:
    Detected unit: milliseconds
    Method: pattern hint (durationMS= found)
    Sample values: 125, 250, 89, 1500, 45
```

#### 7. Conversion Function

```perl
sub convert_duration_to_ms {
    my ($value, $unit) = @_;

    return $value * 1000         if $unit eq 's';    # seconds
    return $value                if $unit eq 'ms';   # milliseconds
    return $value / 1000         if $unit eq 'us';   # microseconds
    return $value / 1000000      if $unit eq 'ns';   # nanoseconds

    return $value;  # default: assume milliseconds
}
```

**Precision Requirements:**
- Use floating-point for all conversions
- `0.001` seconds -> `1.0` ms (not truncated)
- `1500` microseconds -> `1.5` ms

#### 8. Per-File Detection

Each file maintains its own detected unit:
- Detection occurs independently per file
- Stored in a per-file data structure
- Allows mixing logs from different servers

```perl
my %file_duration_unit;  # { 'path/to/file.log' => 'us', ... }
```

### Non-Functional Requirements

1. **Performance**: Detection uses only first 1000 lines with duration values
2. **Accuracy**: Pattern hints should achieve 99%+ accuracy; statistical detection ~90%+
3. **Backward Compatibility**: Default behavior (milliseconds) preserved when no flag and no detection triggers
4. **Usability**: Clear feedback about what unit was detected and why

## Implementation Approach

### Look-Ahead Buffer Design

When first duration value is encountered:

```perl
# Pseudocode
my @lookahead_buffer;
my @duration_samples;

# Read ahead to collect samples
while (scalar @duration_samples < 1000 && !eof($fh)) {
    my $line = <$fh>;
    push @lookahead_buffer, $line;

    if (my $duration = extract_duration($line)) {
        push @duration_samples, $duration;
    }
}

# Detect unit from samples
my $detected_unit = detect_duration_unit(\@duration_samples);
$file_duration_unit{$current_file} = $detected_unit;

# Process buffered lines (they need to be processed after detection)
foreach my $buffered_line (@lookahead_buffer) {
    process_line($buffered_line, $detected_unit);
}

# Continue normal processing with detected unit
```

### Integration Points

1. **Command-line parsing** (~line 700): Add `-du`/`--duration-unit` option
2. **File processing loop** (~line 960): Implement look-ahead detection
3. **Duration capture points** (~lines 988, 1020, 1038, etc.): Apply conversion
4. **Progress display** (~line 970): Add unit indicator
5. **Verbose output**: Add detection summary section

## Test Plan

### Test Cases

1. **Manual Override**
   - `-du s` with nginx log -> correct second-to-ms conversion
   - `-du us` with Apache log -> correct microsecond-to-ms conversion
   - `-du invalid` -> error message

2. **Autodetection**
   - Nginx log (values like `0.250`) -> detects seconds
   - Apache log (values like `250000`) -> detects microseconds
   - ThingWorx log with `durationMS=` -> detects milliseconds via pattern hint

3. **Conversion Accuracy**
   - `0.001` s -> `1.0` ms
   - `1500` us -> `1.5` ms
   - `500000000` ns -> `500.0` ms

4. **Warning Scenarios**
   - Log detected as ms but has values > 100,000 -> warning shown
   - Log detected as s but has integer values > 100 -> warning shown

5. **Verbose Output**
   - `-V` flag shows detection details per file
   - Shows method, sample values, detected unit

### Sample Test Commands

```bash
# Nginx seconds
./ltl -du s logs/nginx_access.log
./ltl -hm duration -du s logs/nginx_access.log

# Apache microseconds
./ltl -du us logs/apache_access.log

# Autodetection with verbose output
./ltl -V logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Mixed files (autodetect each)
./ltl logs/AccessLogs/*.txt logs/ThingworxLogs/CustomThingworxLogs/*.log
```

## Progress Tracking

### Research Phase
- [x] Research web server duration formats
- [x] Document unit variations across platforms
- [x] Create feature requirements document
- [x] Update GitHub issue #17
- [x] Create implementation plan
- [x] Document decisions (look-ahead: 1000 samples/10000 lines, 5% warning threshold, -du sets default)

### Implementation Phase
- [x] Add command-line option `-du`/`--duration-unit` with validation
- [x] Add conversion function `convert_duration_to_ms()`
- [x] Add detection function `detect_duration_unit()`
- [x] Add global variables for duration unit tracking
- [ ] **BLOCKED: Architect review needed** - Implement look-ahead buffer for detection
- [ ] Integrate conversion at duration capture points
- [ ] Add progress line unit display
- [ ] Add runtime validation warnings
- [ ] Add verbose output section

### Testing Phase
- [ ] Test with nginx logs (seconds)
- [ ] Test with Apache logs (microseconds)
- [ ] Test with ThingWorx logs (pattern hint)
- [ ] Test warning scenarios
- [ ] Test verbose output

### Documentation Phase
- [ ] Update CLAUDE.md
- [ ] Update help text
- [ ] Add to release notes

## Decisions Made

From implementation planning session:
1. **Look-ahead**: Collect up to 1000 latency samples; give up after 10000 lines if < 100 samples
2. **Pattern hints**: Most specific wins (e.g., `durationMS=` beats bare integers)
3. **Warning threshold**: 5% suspicious values triggers warning
4. **-du scope**: Sets default, but explicit pattern hints can override per-file

## Architectural Decision Required

### Issue: Look-Ahead Detection Mechanism

The current implementation uses a **separate file scan** approach:
- `scan_file_for_duration_unit()` opens the file, reads up to 10000 lines to collect 1000 duration samples
- Uses simplified regex patterns to extract durations (not the full parsing infrastructure)
- Then the main file processing loop opens the file again and processes normally with detected unit

### Concerns Raised

This approach bypasses the existing application parsing context:
1. **Duplicate file reads** - opens and reads the file twice
2. **Pattern mismatch risk** - simplified detection patterns may not match actual parsing patterns
3. **Not integrated with match types** - doesn't leverage the existing log format detection (match_type 1-12)

### Alternative Approaches to Consider

**Option A: Buffered Look-Ahead Within Main Loop**
- On first duration found, buffer subsequent lines
- Continue collecting samples without adding to data model
- After detection, replay buffered lines through normal processing
- Pro: Uses actual parsing infrastructure
- Con: More complex state management, lines processed twice

**Option B: Two-Pass Processing**
- First pass: lightweight scan for duration samples only (current approach)
- Second pass: full processing with detected unit
- Pro: Simple, clean separation
- Con: File read twice, detection patterns may drift from parsing patterns

**Option C: Deferred Conversion**
- Process all lines normally, store raw duration values
- At end of file, analyze all durations and detect unit
- Retroactively convert all stored values
- Pro: Uses actual parsed values
- Con: Memory intensive, requires data structure changes

**Option D: Streaming Detection with Correction**
- Start with default assumption (ms)
- Collect samples during normal processing
- After N samples, if detection differs from assumption, warn user
- Pro: Single pass, no buffering
- Con: Cannot retroactively fix already-processed values

### Questions for Chief Architect

1. Which approach best fits the existing architecture philosophy?
2. Is the duplicate file read acceptable for the simplicity it provides?
3. Should detection patterns mirror the exact parsing patterns used in match types?
4. How should detection interact with the existing `$is_access_log` flag?
