# Feature Requirements: Removal of Redundant Data Structures and Normalization of Data Model Access Patterns

## Branch
`redundant-data-structure-removal`

## Overview
<!-- Provide a high-level description of the feature -->
Presently the application contains a few areas where there are intermediate local variable data structures which simply map to global variables.  Given that this pattern uses more memory, as well as is not applied with the same naming and access patterns, it makes it very confusing for software developers.  The goal of this feature is to remove redundancy, improve coherence and comprehension of the code base and the data model to remove tehcnical debt and prepare for faster feature addtion going forward.

## Background / Problem Statement
<!-- Describe the problem this feature solves or the need it addresses -->
Redundant and inconsistently named data structures and access patterns make refactoring and writing new features complicated when they are not the same thoughout the application.  Lack of standardization and coherence leads to slow debugging and new feature development.

## Goals
<!-- List the main goals of this feature -->
- Access to and referencing the global hashes should use the same format and access patterns throughout the code
- Redundant local variables should be removed and replaced with direct reference to the global data structures
- Global data structure access patterns should be normalized so that they are using the same variables and patterns across the code base for clarity and understanding
- Overall code readability and coherence should be improved
- Remove technical debt due to various disjointed copied code snippets from Copilot
- Improve feature development speed

## Requirements

### Functional Requirements
<!-- List what the feature must do -->
- Current application functionality should remain unchanged

### Non-Functional Requirements
<!-- List performance, usability, compatibility, etc. requirements -->
- Memory usage and possibly performance should increase due to less memory management operations
- Code becomes more readable with and common data model used and referenced in the same way throughout the application (likely requires renaming some variables)
- 

## User Stories
<!-- Describe the feature from the user's perspective -->
- As a Software Developer, I should be able to easily read and understand the global data structures and their access patterns in simple manner across the various parts of the application
- As an Infrastructure Administrator, I should be sure that the resources required for processing very large files are only what is strictly necessary

## Acceptance Criteria
<!-- Define what "done" looks like -->
- [ ] Statists outputs (-o) in STATS and MESSAGE files should be the same before and after the removal of redundant data structures
- [ ] Uneeded hash or list variables should be removed, avoiding excessive allocation, and referencing global variables instead of making new local ones
- [ ] Current code format, design, and variable structure remains unchanged

## Technical Considerations
<!-- Any technical notes, dependencies, or implementation considerations -->
- Redundant data structures should be removed, nothing else
- Any technical clarification questions should be asked for the master

### Specific Redundant Patterns to Remove

The following intermediate local variable patterns must be replaced with direct access to the global hashes:

1. **Hash reference aliases** - Local variables that store a reference to a sub-hash, then access via `$local->{key}`:
   - `my $bucket_data = $log_analysis{$bucket};` (line ~1141) - Replace all `$bucket_data->{key}` with `$log_analysis{$bucket}{key}`
   - `my $message_data = $log_messages{$category}{$log_key};` (line ~1266) - Replace all `$message_data->{key}` with `$log_messages{$category}{$log_key}{key}`

2. **Bulk value extractions in print sections** - KEEP AS-IS for readability:
   - Lines ~2324-2348: 23 variables extracted from `$log_messages{$grouping}{$key}{...}` - These are in the print/output section which runs only once per message (few iterations). Keep for code readability and coherence. The focus should be on data processing loops that run millions of times, not output formatting sections.

3. **Unused variables** - Variables assigned but never referenced:
   - `my $impact = $log_messages{$category}{$log_key}{impact};` (line ~1281) - Remove entirely (already removed as part of $message_data refactoring)

### Global Data Structures (Reference)
These are the canonical global hashes that should be accessed directly:
- `%log_occurrences` - Log entry counts across time buckets
- `%log_analysis` - Aggregated statistics per time bucket
- `%log_messages` - Per-message statistics
- `%log_stats` - Statistical calculations (percentiles, stddev, cv, z-scores)
- `%log_threadpools` - Thread pool information
- `%threadpool_activity` - Thread pool activity metrics
- `%log_userdefinedmetrics` - Custom user-defined metrics

## Out of Scope
<!-- What is explicitly not included in this feature -->
- 

## Testing Requirements
<!-- What testing is needed -->
- Run ltl tool with test log files BEFORE changes and capture:
  - STATS and MESSAGE CSV output files for comparison
  - Execution times (FILE PROCESSING TIME, CALCULATE STATISTICS, TOTAL TIME)
- Run ltl tool with same log files AFTER changes and compare:
  - CSV outputs should be identical (verify statistical correctness)
  - Execution times should be similar or improved (memory operations reduced)
- Test with various flags (-os, -od, -ob, -ov) to ensure all code paths work

### Test Results

#### Test 1: Small Log File (608 lines)
**Command:** `ltl -o logs/ApplicationLog.2025-12-12.282-Windows.log`

| Metric | Before | After |
|--------|--------|-------|
| LINES READ | 608 | 608 |
| FILE PROCESSING TIME | 138.9 msec | 137.6 msec |
| CALCULATE STATISTICS | 215 usec | 199 usec |
| TOTAL TIME | 139.5 msec | 138.1 msec |

**CSV Verification:** STATS identical, MESSAGES identical

#### Test 2: Large Access Log Files (3.3M lines)
**Command:** `ltl -n 50 -dmin 50 -o accessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-0*`

| Metric | Before | After |
|--------|--------|-------|
| LINES READ | 3,325,508 | 3,325,508 |
| LINES INCLUDED | 821,924 | 821,924 |
| FILE PROCESSING TIME | 27.0 sec | 26.9 sec |
| CALCULATE STATISTICS | 455.7 msec | 456.1 msec |
| SCALE DATA TO TERMINAL | 1.2 msec | 1.1 msec |
| TOTAL TIME | 27.4 sec | 27.4 sec |

**CSV Verification:** STATS identical, MESSAGES identical

## Documentation Requirements
<!-- What documentation needs to be updated -->
- Feature requirements document updated with technical considerations and test results

## Notes
<!-- Any additional notes or considerations -->
- Performance is consistent before and after changes on both small and large datasets
- All statistical outputs verified identical, confirming no functional regression

