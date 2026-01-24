# Feature Requirements: Pattern Match File for Filters

## GitHub Issue
[Issue #19: Feature allowing use of a pattern match file filter options include, exclude, highlight](https://github.com/gregeva/logtimeline/issues/19)

## Related Issues
- [Issue #20: Configuration directory for pattern files and settings](https://github.com/gregeva/logtimeline/issues/20) - Future enhancement

## Branch
`feature/pattern-match-file`

## Overview
Add the ability to specify filter patterns (include, exclude, highlight) via files instead of command line arguments. This feature allows users to maintain reusable lists of patterns and simplifies command lines when filtering by many patterns.

## Background / Problem Statement

### Current Limitation
Users must specify all filter patterns directly on the command line:
```bash
ltl --exclude "healthcheck|ping|favicon|status" --highlight "POST /api/users|PUT /api/users" logs/*.log
```

For complex filtering scenarios (e.g., isolating a specific application's API traffic from a load balancer log), the command line becomes unwieldy:
```bash
ltl --highlight "GET /app/api/endpoint1|GET /app/api/endpoint2|POST /app/api/endpoint3|..." logs/*.log
```

### Proposed Solution
Allow patterns to be specified in files, one pattern per line:
```bash
# health-checks.txt
/health
/ping
/favicon.ico
/status

# application-apis.txt
POST /app/api/users
GET /app/api/orders
PUT /app/api/config
```

Command line becomes:
```bash
ltl --exclude-file health-checks.txt --highlight-file application-apis.txt logs/*.log
```

### Use Case Example
Analyzing traffic for a specific application on a shared web server:
1. Create a file listing all APIs the application uses
2. Use `--highlight-file` to visually separate that application's traffic
3. Create a file listing health check and monitoring endpoints
4. Use `--exclude-file` to remove noise from analysis

## Goals
- Add `--include-file`, `--exclude-file`, and `--highlight-file` command line options
- Allow combining file-based patterns with existing regex patterns
- Ensure security by escaping special regex characters in file patterns (using Perl's `quotemeta`)
- Provide clear error messages and visual indicators for file access issues
- Add `--verbose` flag to display merged regex patterns for debugging
- Maintain backward compatibility with existing options

## Requirements

### Functional Requirements

1. **Command Line Interface**
   - Add `-if` / `--include-file <filename>` option
   - Add `-ef` / `--exclude-file <filename>` option
   - Add `-hf` / `--highlight-file <filename>` option
   - Add `-V` / `--verbose` flag for debugging (shows merged regex patterns)
   - Single file per filter type (no multiple files for same option)
   - All file options can be combined with their regex counterparts
   - Examples:
     - `./ltl --exclude-file health-checks.txt logs/access.log`
     - `./ltl -ef health.txt -e "DEBUG|TRACE" logs/app.log`
     - `./ltl --highlight-file apis.txt --highlight "critical" logs/*.log`
     - `./ltl -V --exclude-file patterns.txt logs/*.log` (shows merged regex)

2. **Pattern File Format**
   - One pattern per line
   - **Patterns are literal strings only** (not regex) - all special characters are escaped
   - Empty lines are ignored
   - Lines starting with `#` are treated as comments and ignored
   - **No inline comments** - `#` after content is treated as part of the pattern
   - **Whitespace is preserved exactly** - leading and trailing spaces are significant
     - Example: `" ERROR "` matches only when surrounded by spaces
     - Example: `"GET /api/users "` with trailing space is distinct from `"GET /api/users/123"`
   - File must be plain text (UTF-8 or ASCII)

3. **Pattern Processing**
   - Use Perl's `quotemeta` function to escape ALL non-alphanumeric characters
   - Concatenate patterns with `|` (OR) to form a single regex
   - Merge file patterns with command line patterns (both are OR'd together)
   - **Case-sensitive matching** (patterns match exactly as written)

4. **Pattern Merging Logic**
   When both file and command line patterns are provided for the same filter type:
   ```perl
   # If user provides: --exclude "DEBUG" --exclude-file noise.txt
   # And noise.txt contains: healthcheck, favicon
   # Result: $exclude_regex = "DEBUG|healthcheck|favicon"
   ```

5. **Security and Limits**
   - **Regex Escaping**: Use `quotemeta` to escape all non-alphanumeric characters
   - **File Size Limit**: Reject files larger than 10KB
   - **Pattern Count Limit**: Maximum 1,000 patterns per file (warn if exceeded, but use all)
   - **Regex Length Warning**: Warn if merged regex exceeds 10KB (10,240 characters)
   - **Binary Detection**: Check for null bytes in first 8KB; reject binary files
   - **Path Handling**: Use `File::Spec` for cross-platform path support (both `/` and `\` accepted)
   - **Encoding**: Assume UTF-8; warn on invalid UTF-8 sequences
   - **Whitespace-only lines**: Lines containing only whitespace (spaces/tabs) are treated as empty lines and ignored

6. **Error Handling Behavior**
   - **Warn and continue** - do not abort on file errors
   - All warnings go to **STDERR** (not STDOUT)
   - File issues are indicated in the options line with visual markers
   - Processing continues with available patterns (or no pattern if file failed)
   - When limits are exceeded (pattern count, regex length), warn but continue with all patterns

7. **Visual Indicators in Options Line**
   The options output line (dark gray / `bright-black`) will show file status:
   - Normal: `--exclude-file health.txt` (no indicator - file loaded successfully)
   - Empty file: `--exclude-file health.txt!` (dark gray `!` - file readable but no patterns)
   - Read error: `--exclude-file health.txt!!` (dark gray `!!` - file not found or unreadable)

   Example output:
   ```
   options: -ef health.txt! -hf apis.txt -n 10
   ```

8. **Verbose Mode (`-V` / `--verbose`)**
   When enabled, print merged regex patterns using normal foreground color (NC/reset):
   ```
   === Verbose ===
   include: (not set)
   exclude: healthcheck|ping|favicon\.ico|status
   highlight: POST\ /app/api/users|GET\ /app/api/orders
   ```
   - Header line followed by simple labeled lines
   - Shows "(not set)" for filters without patterns
   - Printed to STDOUT before processing begins

### Non-Functional Requirements

1. **Performance**
   - File reading happens once during initialization
   - No impact on log processing performance
   - Memory usage proportional to pattern file size

2. **Compatibility**
   - Works on all platforms (Unix, macOS, Windows)
   - File paths support both forward slashes (`/`) and backslashes (`\`)
   - Handles files with different line endings (LF, CRLF, CR)

3. **Usability**
   - Visual indicators in options line show file status at a glance
   - Verbose mode helps debug pattern matching issues
   - Help text updated with new options and examples

## User Stories

- As a System Administrator, I want to maintain a file of health check URLs to exclude, so I can reuse it across multiple log analysis sessions
- As a Performance Engineer, I want to highlight specific API endpoints from a file, so I can quickly compare different application traffic patterns
- As a Developer, I want to combine file-based patterns with command line patterns, so I can use a baseline exclusion list while adding session-specific filters
- As a Troubleshooter, I want to use verbose mode to see the merged regex, so I can debug why patterns aren't matching as expected
- As a User, I want to see visual indicators when pattern files have issues, so I know immediately if my filters are active

## Acceptance Criteria

### File Processing
- [x] `-if`/`--include-file` option is recognized
- [x] `-ef`/`--exclude-file` option is recognized
- [x] `-hf`/`--highlight-file` option is recognized
- [x] `-V`/`--verbose` option is recognized
- [x] Patterns are read from file, one per line
- [x] Comment lines (starting with `#`) are ignored
- [x] Empty lines are ignored
- [x] Whitespace is preserved exactly (not trimmed)
- [x] All non-alphanumeric characters are escaped with `quotemeta`
- [x] Matching is case-sensitive

### Visual Indicators
- [x] Options line shows filename for file-based filters
- [x] Empty file indicator (`!`) appears after filename when no patterns loaded
- [x] Error indicator (`!!`) appears after filename when file cannot be read
- [x] Indicators are gray (bright-black) color

### Verbose Mode
- [x] `-V`/`--verbose` flag works
- [x] Merged regex patterns are printed when verbose is enabled
- [x] Output clearly labels which filter type each regex is for

### Pattern Merging
- [x] File patterns work standalone
- [x] File patterns merge with command line regex patterns
- [x] Multiple patterns from file are OR'd together
- [x] Merged patterns work correctly for filtering

### Error Handling
- [x] Missing file produces warning and continues (with `!!` indicator)
- [x] Unreadable file produces warning and continues (with `!!` indicator)
- [x] Empty file produces warning and continues (with `!` indicator)
- [x] Binary file produces warning and continues (with `!!` indicator)
- [x] Large file (>10KB) produces warning and continues (with `!!` indicator)

### Integration
- [x] Works with existing `-include`/`-exclude`/`-highlight` options
- [x] Works with heatmap mode
- [ ] Works with CSV output
- [x] Usage help includes new options

## Technical Considerations

### Data Structures
New variables needed:
```perl
my ($include_file, $exclude_file, $highlight_file);   # File paths from command line
my $verbose = 0;                                       # Verbose mode flag

# Limits and thresholds
my $pattern_file_max_size = 10 * 1024;              # 10KB file size limit
my $pattern_file_max_patterns = 1000;                  # Max patterns per file (warn if exceeded)
my $pattern_regex_max_length = 10240;                  # 10KB regex length warning threshold

# Track file status for visual indicators
my %pattern_file_status = (
    'include'   => { file => undef, status => 'ok', count => 0 },  # status: ok, empty, error
    'exclude'   => { file => undef, status => 'ok', count => 0 },
    'highlight' => { file => undef, status => 'ok', count => 0 },
);
```

### New Subroutines

1. **`read_pattern_file($filename, $filter_type)`**
   - Reads file, validates it, returns array of patterns
   - Updates `%pattern_file_status` with result
   - Handles errors gracefully (warns, doesn't die)
   - Strips comments and empty lines (but preserves whitespace in patterns)

2. **`build_merged_regex($cli_regex, @file_patterns)`**
   - Combines command line regex with file patterns
   - Uses `quotemeta` on file patterns
   - Returns merged regex string

3. **`get_pattern_file_indicator($filter_type)`**
   - Returns visual indicator string based on file status
   - Returns `''` for ok, `'!'` for empty, `'!!'` for error

### Integration Points

1. **Command Line Parsing** (~line 574): Add new GetOptions entries
   ```perl
   'include-file|if=s' => \$include_file,
   'exclude-file|ef=s' => \$exclude_file,
   'highlight-file|hf=s' => \$highlight_file,
   'verbose|V' => \$verbose,
   ```

2. **After Command Line Parsing** (~line 610): Process pattern files
   ```perl
   if ($include_file) {
       my @patterns = read_pattern_file($include_file, 'include');
       $include_regex = build_merged_regex($include_regex, @patterns) if @patterns;
   }
   # Similar for exclude_file and highlight_file

   # Verbose output (uses normal foreground color via NC/reset)
   if ($verbose) {
       print "=== Verbose ===\n";
       print "include: " . (defined $include_regex ? $include_regex : "(not set)") . "\n";
       print "exclude: " . (defined $exclude_regex ? $exclude_regex : "(not set)") . "\n";
       print "highlight: " . (defined $highlight_regex ? $highlight_regex : "(not set)") . "\n";
   }
   ```

3. **Options Output** (~line 2655): Add file indicators
   ```perl
   # When printing options, include file indicators
   if ($exclude_file) {
       my $indicator = get_pattern_file_indicator('exclude');
       print "--exclude-file $exclude_file$indicator ";
   }
   ```

4. **Usage Help** (~line 288): Add new options to usage string

### Pattern Escaping Implementation
```perl
sub escape_pattern {
    my ($pattern) = @_;
    # Use quotemeta for comprehensive escaping of all non-alphanumeric characters
    return quotemeta($pattern);
}
```

### File Reading Implementation
```perl
sub read_pattern_file {
    my ($filename, $filter_type) = @_;
    my @patterns;

    # Record the file being processed
    $pattern_file_status{$filter_type}{file} = $filename;

    # Use File::Spec for cross-platform path handling
    $filename = File::Spec->canonpath($filename);

    # Validate file exists
    unless (-e $filename) {
        print STDERR "Warning: Pattern file not found: $filename\n";
        $pattern_file_status{$filter_type}{status} = 'error';
        return ();
    }

    # Check file size
    my $size = -s $filename;
    if ($size > $pattern_file_max_size) {
        print STDERR "Warning: Pattern file exceeds maximum size (10KB): $filename\n";
        $pattern_file_status{$filter_type}{status} = 'error';
        return ();
    }

    # Check for binary (null bytes in first 8KB)
    unless (open my $fh, '<:raw', $filename) {
        print STDERR "Warning: Cannot read pattern file: $filename ($!)\n";
        $pattern_file_status{$filter_type}{status} = 'error';
        return ();
    }
    my $header;
    read($fh, $header, 8192);
    if ($header =~ /\x00/) {
        close $fh;
        print STDERR "Warning: Pattern file appears to be binary: $filename\n";
        $pattern_file_status{$filter_type}{status} = 'error';
        return ();
    }
    close $fh;

    # Read file as text
    unless (open my $fh, '<:encoding(UTF-8)', $filename) {
        print STDERR "Warning: Cannot read pattern file: $filename ($!)\n";
        $pattern_file_status{$filter_type}{status} = 'error';
        return ();
    }
    while (<$fh>) {
        s/\r?\n$//;               # Remove line endings (handles LF, CRLF)
        next if /^#/;             # Skip comment lines
        next if /^$/;             # Skip empty lines
        next if /^\s+$/;          # Skip whitespace-only lines
        # Whitespace within content is preserved - no trimming
        push @patterns, $_;
    }
    close $fh;

    if (@patterns == 0) {
        print STDERR "Warning: Pattern file is empty: $filename\n";
        $pattern_file_status{$filter_type}{status} = 'empty';
        return ();
    }

    # Warn if pattern count exceeds limit (but use all patterns)
    if (@patterns > $pattern_file_max_patterns) {
        print STDERR "Warning: Pattern file contains " . scalar(@patterns) .
                     " patterns (exceeds recommended limit of $pattern_file_max_patterns): $filename\n";
    }

    $pattern_file_status{$filter_type}{status} = 'ok';
    $pattern_file_status{$filter_type}{count} = scalar(@patterns);
    return @patterns;
}

sub build_merged_regex {
    my ($cli_regex, @file_patterns) = @_;

    # Escape file patterns using quotemeta
    my @escaped = map { quotemeta($_) } @file_patterns;

    # Build merged regex
    my $file_regex = join('|', @escaped);

    my $merged;
    if (defined $cli_regex && $cli_regex ne '') {
        $merged = "$cli_regex|$file_regex";
    } else {
        $merged = $file_regex;
    }

    # Warn if merged regex exceeds length threshold
    if (length($merged) > $pattern_regex_max_length) {
        print STDERR "Warning: Merged regex pattern is " . length($merged) .
                     " characters (exceeds recommended limit of $pattern_regex_max_length)\n";
    }

    return $merged;
}

sub get_pattern_file_indicator {
    my ($filter_type) = @_;
    my $status = $pattern_file_status{$filter_type}{status};
    return '' if $status eq 'ok';
    return '!' if $status eq 'empty';
    return '!!' if $status eq 'error';
    return '';
}
```

## Test Plan

### Unit Tests

1. **Pattern Escaping Tests**
   ```
   Input: "/api/users?id=123"
   Expected (with quotemeta): "\/api\/users\?id\=123"

   Input: "log[ERROR]"
   Expected: "log\[ERROR\]"

   Input: "simple text"
   Expected: "simple\ text"

   Input: " ERROR " (with spaces)
   Expected: "\ ERROR\ "
   ```

2. **File Reading Tests**
   - Test with valid pattern file
   - Test with comments and empty lines
   - Test with various line endings (LF, CRLF)
   - Test with leading/trailing whitespace (preserved)
   - Test that inline `#` is NOT treated as comment

3. **Error Handling Tests**
   - Test with non-existent file (returns empty, status=error)
   - Test with unreadable file (returns empty, status=error)
   - Test with binary file (returns empty, status=error)
   - Test with oversized file (returns empty, status=error)
   - Test with empty file (returns empty, status=empty)

4. **Visual Indicator Tests**
   - Test indicator shows nothing for successful load
   - Test indicator shows `!` for empty file
   - Test indicator shows `!!` for error conditions

### Integration Tests

1. **Basic Filtering**
   ```bash
   # Create test pattern file
   cat > /tmp/exclude.txt << 'EOF'
   healthcheck
   ping
   favicon
   EOF

   # Test exclude file
   ./ltl --exclude-file /tmp/exclude.txt logs/AccessLogs/localhost_access_log.2025-03-21.txt
   ```

2. **Pattern Merging**
   ```bash
   # Test combining file and CLI patterns
   ./ltl --exclude "DEBUG" --exclude-file /tmp/exclude.txt logs/*.log
   ```

3. **Whitespace Preservation**
   ```bash
   # Create pattern with significant whitespace
   cat > /tmp/spaced.txt << 'EOF'
    ERROR
   EOF

   # Should match " ERROR " but not "ERROR" or "MYERROR"
   ./ltl --highlight-file /tmp/spaced.txt logs/*.log
   ```

4. **Verbose Mode**
   ```bash
   ./ltl -V --exclude-file /tmp/exclude.txt logs/*.log
   # Should output: verbose: exclude_regex = healthcheck|ping|favicon
   ```

5. **Error Indicators**
   ```bash
   # Test with non-existent file
   ./ltl --exclude-file /tmp/nonexistent.txt logs/*.log
   # Options line should show: --exclude-file /tmp/nonexistent.txt!!
   ```

6. **All Three File Types**
   ```bash
   echo "POST" > /tmp/include.txt
   echo "health" > /tmp/exclude.txt
   echo "users" > /tmp/highlight.txt

   ./ltl -if /tmp/include.txt -ef /tmp/exclude.txt -hf /tmp/highlight.txt logs/AccessLogs/*.txt
   ```

7. **Heatmap Compatibility**
   ```bash
   ./ltl -hm duration --highlight-file /tmp/apis.txt logs/AccessLogs/*.txt
   ```

### Manual Testing
- Test on macOS, Linux, and Windows
- Test with files containing non-ASCII characters (UTF-8)
- Test with Windows-style paths on Windows

## Documentation Requirements

- Update README.md with new options and examples
- Update `print_usage()` with new options
- Add example pattern files in repository (optional: `examples/` directory)
- Update CLAUDE.md if architecture changes

## Future Considerations

### Config Folder (Issue #20)
A future enhancement will add a config directory for commonly used pattern files:
- `~/.ltl/patterns/` on Unix
- `%APPDATA%\ltl\patterns\` on Windows
- Allow referencing patterns by name: `--exclude-file @health-checks`

### Multiple Files per Option (Out of Scope for v1)
Allow specifying multiple files per option:
```bash
./ltl --exclude-file noise.txt --exclude-file debug.txt logs/*.log
```

### Regex Mode in Files (Out of Scope for v1)
Allow regex patterns in files with special prefix:
```
# patterns.txt
literal string match
regex:^DEBUG.*$
```

---

## Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Pattern type in files** | Literal strings only | Security - prevents regex injection; simplicity |
| **Regex escaping** | Perl `quotemeta` | Comprehensive, well-tested, handles all edge cases |
| **Multiple files per option** | Single file only | Simplicity for v1; can extend later |
| **Case sensitivity** | Case-sensitive | Patterns match exactly as written |
| **Whitespace handling** | Preserve exactly | Log messages may require whitespace for unique matching |
| **Whitespace-only lines** | Treated as empty | Lines with only spaces/tabs are ignored |
| **Inline comments** | Not supported | Avoids issues with `#` in URLs and patterns |
| **Error behavior** | Warn and continue | More forgiving; visual indicators show status |
| **Warning output** | STDERR | Standard Unix practice, doesn't mix with data |
| **Visual indicators** | `!` empty, `!!` error | Quick visual feedback in options line (dark gray) |
| **Verbose flag** | `-V` / `--verbose` | Uppercase V avoids conflict with `-v` (version) |
| **Verbose format** | Header + simple lines | `=== Verbose ===` then `exclude: pattern` lines |
| **Verbose color** | Normal FG (NC/reset) | Standard readable text |
| **Pattern count limit** | 1,000 patterns | Warn if exceeded, but use all |
| **Regex length warning** | 10KB (10,240 chars) | Warn if merged regex exceeds threshold |
| **Limit exceeded behavior** | Warn and continue | Advisory warning, still processes all patterns |
| **Config directory** | Deferred to Issue #20 | Keep v1 simple; natural future enhancement |
| **Path handling** | File::Spec | Cross-platform compatibility |

---

## Implementation Order

The implementation follows a "core first" approach, building foundational functionality before adding enhancements:

### Phase 1: Core File Reading
1. Add global variables (file paths, limits, status tracking)
2. Implement `read_pattern_file()` function
   - File existence check
   - Size validation
   - Binary detection
   - Pattern extraction (with comment/empty line handling)
   - Whitespace-only line handling
   - Pattern count warning

### Phase 2: Pattern Processing
3. Implement `build_merged_regex()` function
   - `quotemeta` escaping
   - Pattern joining with `|`
   - CLI + file pattern merging
   - Regex length warning

### Phase 3: CLI Integration
4. Add command line options to GetOptions
   - `-if`/`--include-file`
   - `-ef`/`--exclude-file`
   - `-hf`/`--highlight-file`
   - `-V`/`--verbose`
5. Wire up pattern file processing after CLI parsing
6. Update `print_usage()` with new options

### Phase 4: Visual Feedback
7. Implement `get_pattern_file_indicator()` function
8. Update options output line to show file indicators
9. Add verbose output (header + labeled lines)

### Phase 5: Testing & Documentation
10. Run test suite (unit tests, integration tests)
11. Update README.md and CLAUDE.md

---

## Progress Tracking

### Research Phase
- [x] Review GitHub issue #19 requirements
- [x] Analyze current include/exclude/highlight implementation
- [x] Research security best practices for file input
- [x] Document feature requirements
- [x] Create GitHub issue #20 for config directory feature

### Planning Phase
- [x] Create feature documentation file
- [x] Define acceptance criteria
- [x] Refine requirements through user discussion
- [x] Document design decisions
- [x] Define verbose output format (header + simple lines)
- [x] Define warning output destination (STDERR)
- [x] Define whitespace-only line handling (treat as empty)
- [x] Define pattern count limit (1,000) and behavior (warn, continue)
- [x] Define regex length warning threshold (10KB)
- [x] Define implementation order (core first)
- [ ] Final review with user

### Scheduling Phase
- [x] Confirm implementation order (5 phases)
- [x] Estimate complexity: **Low-Medium**
  - ~150-200 lines of new Perl code
  - No new dependencies required
  - Straightforward integration with existing code

### Implementation Phase
**Phase 1: Core File Reading**
- [x] Add global variables for file paths, limits, and status tracking
- [x] Implement `read_pattern_file()` function

**Phase 2: Pattern Processing**
- [x] Implement `build_merged_regex()` function

**Phase 3: CLI Integration**
- [x] Add command line options (`-if`, `-ef`, `-hf`, `-V`)
- [x] Integrate pattern file processing after CLI parsing
- [x] Update `print_usage()` with new options
- [x] Configure Getopt::Long with `no_ignore_case` for case-sensitive options

**Phase 4: Visual Feedback**
- [x] Implement `get_pattern_file_indicator()` function
- [x] Update options output line with file indicators
- [x] Add verbose output for merged regex patterns

**Phase 5: Testing & Documentation**
- [x] Run test suite (macOS)
- [ ] Update README.md
- [ ] Update CLAUDE.md if needed

### Testing Phase
- [x] Test pattern escaping with `quotemeta`
- [x] Test file reading (various formats, line endings)
- [x] Test whitespace preservation
- [x] Test error handling (all error cases)
- [x] Test visual indicators (`!`, `!!`)
- [x] Test verbose mode output
- [x] Test pattern merging
- [x] Test with real log files
- [x] Test on macOS
- [ ] Test on Linux
- [ ] Test on Windows

### Validation Phase
- [x] Verify all acceptance criteria met
- [x] Verify backward compatibility
- [x] Verify error messages and indicators are clear
- [x] Verify verbose output is helpful

### Documentation Phase
- [ ] Update README.md
- [ ] Update CLAUDE.md if needed

---

## Documentation Content (Draft)

The following documentation content should be added to README.md when this feature is complete:

### Pattern Filter Files

Instead of specifying filter patterns directly on the command line, you can load them from files. This is useful when:
- You have many patterns to filter
- You want to reuse pattern sets across multiple analyses
- You want to maintain documented, version-controlled pattern lists

#### Command Line Options

| Option | Description |
|--------|-------------|
| `-if`, `--include-file <file>` | Include only lines matching patterns from file |
| `-ef`, `--exclude-file <file>` | Exclude lines matching patterns from file |
| `-hf`, `--highlight-file <file>` | Highlight lines matching patterns from file |
| `-V`, `--verbose` | Show merged regex patterns for debugging |

#### Pattern File Format

```
# This is a comment (lines starting with # are ignored)
# Empty lines are also ignored

# Each line is a literal string pattern (not regex)
/health
/ping
/favicon.ico

# Whitespace is preserved - this matches " ERROR " with spaces
 ERROR

# Special regex characters are automatically escaped
# This matches the literal string "/api/users?id=123"
/api/users?id=123
```

**Rules:**
- One pattern per line
- Lines starting with `#` are comments
- Empty lines and whitespace-only lines are ignored
- All other whitespace (leading, trailing, internal) is preserved
- Patterns are literal strings - regex special characters are automatically escaped
- Matching is case-sensitive

#### Combining File and CLI Patterns

File patterns can be combined with command line regex patterns. Both are OR'd together:

```bash
# Exclude patterns from file AND the DEBUG regex
ltl --exclude-file noise.txt --exclude "DEBUG|TRACE" logs/app.log

# Include from file, exclude from CLI
ltl --include-file my-apis.txt --exclude "health" logs/access.log
```

#### Examples

**Basic usage:**
```bash
# Create a file of patterns to exclude
cat > health-checks.txt << 'EOF'
/health
/ping
/favicon.ico
/status
EOF

# Use it to filter out health check noise
ltl --exclude-file health-checks.txt logs/access.log
```

**Highlighting specific APIs:**
```bash
# Create a file listing your application's APIs
cat > my-app-apis.txt << 'EOF'
POST /api/users
GET /api/orders
PUT /api/config
EOF

# Highlight your app's traffic in a shared server log
ltl --highlight-file my-app-apis.txt logs/access.log
```

**Debugging with verbose mode:**
```bash
# See exactly what regex patterns are being used
ltl -V --exclude-file patterns.txt logs/access.log

# Output shows:
# === Verbose ===
# include: (not set)
# exclude: \/health|\/ping|\/favicon\.ico
# highlight: (not set)
```

#### Visual Indicators

The options output line shows the status of pattern files:

| Indicator | Meaning |
|-----------|---------|
| `--exclude-file health.txt` | File loaded successfully |
| `--exclude-file health.txt!` | File is empty (no patterns after filtering comments) |
| `--exclude-file health.txt!!` | File error (not found, unreadable, binary, or too large) |

#### Limits

| Limit | Value | Behavior |
|-------|-------|----------|
| Maximum file size | 10 KB | File rejected with error |
| Maximum patterns per file | 1,000 | Warning printed, all patterns used |
| Maximum merged regex length | 10 KB | Warning printed, regex still used |

---

## Release Notes (Draft)

The following release notes content should be included when this feature is packaged into a release:

```markdown
## What's New

### Pattern Match Files for Filters
You can now specify filter patterns (include, exclude, highlight) via files instead of command line arguments. This simplifies complex filtering scenarios and enables reusable pattern sets.

**New command line options:**
- `-if` / `--include-file <file>` - Include patterns from file
- `-ef` / `--exclude-file <file>` - Exclude patterns from file
- `-hf` / `--highlight-file <file>` - Highlight patterns from file
- `-V` / `--verbose` - Show merged regex patterns for debugging

**Pattern file format:**
- One pattern per line (literal strings, not regex)
- Lines starting with `#` are comments
- Empty lines are ignored
- Whitespace is preserved (for matching " ERROR " vs "ERROR")

**Example usage:**
```bash
# Create a pattern file
cat > health-checks.txt << 'EOF'
/health
/ping
/favicon.ico
EOF

# Use it to exclude health check noise
ltl --exclude-file health-checks.txt logs/access.log

# Combine with CLI patterns
ltl -ef health-checks.txt -e "DEBUG" logs/access.log

# Debug with verbose mode
ltl -V --exclude-file patterns.txt logs/access.log
```

**Visual indicators in options line:**
- `--exclude-file health.txt` - File loaded successfully
- `--exclude-file health.txt!` - File empty (no patterns)
- `--exclude-file health.txt!!` - File error (not found/unreadable)

**Limits:**
- Maximum file size: 10KB
- Maximum patterns per file: 1,000 (warning only)
- Maximum merged regex length: 10KB (warning only)
```

---

## External References

### Security
- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)
- [Perl Security](https://perldoc.perl.org/perlsec)

### Perl
- [quotemeta function](https://perldoc.perl.org/functions/quotemeta) - Built-in Perl function for escaping regex metacharacters
- [Getopt::Long](https://perldoc.perl.org/Getopt::Long) - Command line option parsing
- [File::Spec](https://perldoc.perl.org/File::Spec) - Cross-platform file path handling
