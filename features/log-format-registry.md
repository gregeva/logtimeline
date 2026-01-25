# Feature Requirements: Log Format Registry

## Overview

Refactor the core parsing architecture from an implicit match-type conditional chain to a data-driven format registry. This enables format-aware features, user-extensible format definitions, and improved processing performance.

## Background / Problem Statement

### Current Architecture

The main parsing loop in `read_and_process_logs()` uses a numbered match-type system:
- 12+ conditional branches, each with a regex pattern
- Match type is determined implicitly by which regex matches first
- Format metadata (like duration unit) is not captured
- The `$is_access_log` flag is a boolean that loses format-specific information

```perl
# Current approach (simplified)
if ($_ =~ /ThingWorx pattern/) {
    $match_type = 1;
    # extract fields positionally
}
elsif ($_ =~ /Access log pattern/) {
    $match_type = 3;
    $is_access_log = 1;
    # extract fields positionally
}
# ... 10+ more patterns
```

### Problems with Current Approach

1. **No format metadata**: Cannot associate duration units, field names, or other properties with formats
2. **Pattern duplication risk**: If format patterns need to be used elsewhere (e.g., detection), they must be duplicated and may drift
3. **Hard to extend**: Adding a new format requires modifying Perl source code
4. **Implicit knowledge**: The code "knows" match_type 3 is an access log, but this isn't declared anywhere
5. **Performance**: Every line evaluates the full conditional chain until a match is found; for large files matching a pattern late in the chain, this is expensive
6. **No user extensibility**: Users cannot add their own log formats without modifying source

## Motivation

### 1. Performance at Scale

The current chained conditional regex logic is evaluated per line. As the list of supported log formats grows, this becomes exponentially expensive for files that match patterns later in the chain. For a 277MB access log with millions of lines, repeatedly evaluating 12+ regex patterns per line when only the last pattern matches is wasteful.

**Goal**: Once the format is detected for a file, subsequent lines should only run the known pattern's extraction logic, not re-evaluate all patterns for every line.

### 2. User Extensibility

Users have log formats specific to their environments that are not built into the tool. Currently, they cannot add support for their own formats without modifying the Perl source code.

**Goal**: Allow users to define custom log formats via external configuration files, extending the tool's capabilities without code changes.

### 3. Staged Detection with Known Conditions

Detection and processing should happen in stages:
1. **Format Detection**: Identify which log format is being processed
2. **Format-Specific Processing**: Apply format-specific knowledge (field positions, duration unit, etc.)

This staged approach allows using knowns to guide automated determinations. Once we know the format, we can apply all the format-specific rules confidently rather than guessing.

### 4. Duration Unit Autodetection (Issue #17)

The duration unit autodetection feature exposed these architectural limitations. The initial implementation attempted a separate file scan with simplified patterns, which was rejected because:

- **Knowing the field doesn't mean knowing the unit**: Just because we can identify that field 8 contains a duration value doesn't tell us the unit. The same `%D` directive means milliseconds in Tomcat 9 but microseconds in Apache HTTP Server.

- **Similar fields with different semantics**: Nginx access logs may contain `$request_time`, `$upstream_response_time`, `$upstream_connect_time`, and `$time_to_first_byte` - all are durations but with different meanings.

- **Format identification must come first**: Before we can interpret any field, we must know which log format we're dealing with. Detection must happen in stages: first identify the format, then apply format-specific knowledge.

While duration autodetection alone would not justify this refactor, it highlighted the broader architectural issues that affect performance, extensibility, and maintainability.

### 5. Maintainability

Having a single source of truth for format definitions:
- Eliminates pattern drift between detection and processing
- Makes adding new formats straightforward
- Enables format-level testing
- Documents format specifications in a structured way

## Goals

1. **Centralized format definitions**: Each log format defined once with all its properties
2. **Format-aware field extraction**: Once format is identified, use format-specific knowledge for field interpretation
3. **Staged detection**: Detect format first (once per file), then apply format-specific rules for all lines
4. **User extensibility**: Allow users to define custom log formats via external configuration files
5. **Performance optimization**: Once format is detected for a file, skip re-detection for subsequent lines
6. **Duration unit autodetection**: Enable proper autodetection by tying unit knowledge to format definitions
7. **Maintainability**: Single source of truth for format patterns and metadata

## Requirements

### Functional Requirements

#### 1. Format Definition Properties

Each log format definition must include:
- **Pattern**: Regex to match log lines
- **Field mapping**: Which capture groups correspond to which fields (timestamp, message, duration, bytes, etc.)
- **Timestamp format**: How to parse the timestamp
- **Duration field**: Which field contains duration (if any)
- **Duration unit**: The unit for duration values (ns, us, ms, s) - this is format-specific knowledge
- **Access log flag**: Whether this is an access log format
- **Format name/description**: Human-readable identifier
- **Examples**: Sample log lines for documentation and testing

#### 2. Detection Behavior

- Format detection should happen once per file (or until a definitive match is found)
- Once detected, the format should be cached for that file
- Subsequent lines should use the cached format directly, avoiding re-evaluation of all patterns
- Detection should support confidence levels (exact match vs. probable match)

#### 3. User-Defined Formats

- Users should be able to define custom log formats via external configuration file(s)
- User formats should be loaded at startup
- User formats can extend or override built-in formats
- Format validation should catch errors in user definitions

#### 4. Duration Unit Handling

With format registry in place:
- Duration unit is a property of the format definition
- Autodetection works by: identify format → look up format's duration unit → apply conversion
- Manual `-du` override still takes precedence over format-defined unit
- Formats with ambiguous units (same pattern, different units across servers) need disambiguation strategy

#### 5. Ambiguous Format Handling

Some formats have identical patterns but different semantics:
- Tomcat 9 `%D` = milliseconds
- Tomcat 10.1+ `%D` = microseconds
- Apache HTTP Server `%D` = microseconds

The system needs a strategy for disambiguation:
- Filename/path hints
- User specification via command line
- Statistical analysis of values as a fallback
- Clear warning when ambiguity cannot be resolved

### Non-Functional Requirements

1. **Backward Compatibility**: Existing command-line behavior must be preserved
2. **Performance**: Format matching should be faster than current approach for large files
3. **Extensibility**: Adding new built-in formats should be straightforward
4. **Testability**: Format definitions should be testable in isolation
5. **Error Handling**: Clear error messages for malformed user-defined formats

## Current State

- Manual duration unit override (`-du`) is implemented and available (Issue #17)
- Autodetection is deferred pending this refactor
- All format patterns are hardcoded in the main parsing loop

## Dependencies

- Blocks: Duration unit autodetection completion (Issue #17)

## Open Questions

1. What file format should user-defined formats use? (YAML, JSON, custom DSL)
2. How should format priority/ordering work when multiple patterns could match?
3. Should format definitions support inheritance (e.g., "like tomcat9 but with microseconds")?
4. How to handle logs that switch formats mid-file?
5. Should there be a "strict mode" that fails on unrecognized formats vs. current permissive behavior?

## Related

- Issue #17: Duration unit autodetection (blocked by this refactor)
- features/duration-unit-autodetection.md
