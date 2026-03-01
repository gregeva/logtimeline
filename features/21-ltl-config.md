# Feature: LTL_CONFIG Environment Variable

## GitHub Issue
[Issue #21: Support LTL_CONFIG environment variable for default command-line options](https://github.com/gregeva/logtimeline/issues/21)

## Branch
`21-ltl-config`

## Status
Planning

## Overview

Add support for an `LTL_CONFIG` environment variable that provides default command-line options. CLI arguments always take precedence for scalar options; additive options combine from both sources.

### Prerequisite

Make `-i`, `-e`, `-h`, `-tpa` additive on the command line — specifying them multiple times combines patterns with OR, matching the behavior of `-if`/`-ef`/`-hf`.

## Background / Problem Statement

Users must specify all desired options on every invocation of ltl. This is cumbersome for:

- **Team configurations** — teams analyzing the same log types use identical options
- **Personal preferences** — users who always want certain settings (`-lbg`, `-osum`)
- **Environment-specific defaults** — different machines need different configurations

## Behavior

### Environment Variable

```bash
# Set in shell profile (~/.bashrc, ~/.zshrc, etc.)
export LTL_CONFIG="-n 20 -b 5 -lbg -osum -e healthcheck"

# Defaults apply automatically
ltl logfile.log

# CLI overrides scalar options, combines with additive options
ltl -n 50 -e metrics logfile.log
# Result: -n 50 (CLI wins), -b 5, -lbg, -osum, excludes healthcheck AND metrics
```

### Option Precedence

| Priority | Source |
|----------|--------|
| 1 (lowest) | Built-in defaults |
| 2 | `LTL_CONFIG` environment variable |
| 3 (highest) | Command-line arguments |

### Additive Options

These options accumulate values from both `LTL_CONFIG` and CLI (and from multiple uses on the same command line):

| Option | Combination |
|--------|-------------|
| `--include` / `-i` | Patterns combined with OR |
| `--exclude` / `-e` | Patterns combined with OR |
| `--highlight` / `-h` | Patterns combined with OR |
| `--include-file` / `-if` | File lists combined |
| `--exclude-file` / `-ef` | File lists combined |
| `--highlight-file` / `-hf` | File lists combined |
| `--threadpool-activity` / `-tpa` | Patterns combined with OR |
| `--user-defined-metrics` / `-udm` | Metric definitions combined |
| `--udm-csv-message` / `-ucm` | Column names combined |

All other options are scalar — CLI value replaces `LTL_CONFIG` value.

## Output

### Options display (after chart)

The existing "options:" line is renamed. A new line is added when `LTL_CONFIG` is set:

```
environment options: -n 20 -b 5 -lbg -osum -e healthcheck
command-line options: -n 50 -e metrics logfile.log
```

- **"environment options:"** — raw `LTL_CONFIG` string as-is (not parsed or merged)
- **"command-line options:"** — what was passed on the CLI (renamed from "options:")
- Environment line only shown when `LTL_CONFIG` is set and non-empty
- Same `bright-black` color as current "options:" line

### Verbose output (`-V`)

In addition to raw sources, `-V` shows final merged values for all options, useful for debugging.

## Implementation Approach

### Phase 1: Make `-i`, `-e`, `-h`, `-tpa` additive

1. Change GetOptions bindings from scalar to array for these four options
2. After GetOptions, join array elements with `|` into the existing scalar variable
3. Pattern file merging (`build_merged_regex()`) continues to work unchanged

### Phase 2: Parse `LTL_CONFIG`

1. At start of `adapt_to_command_line_options()`, check `$ENV{LTL_CONFIG}`
2. Save raw string for display
3. Parse into array (handle quoted strings)
4. Prepend parsed args to `@ARGV` before `GetOptions`

Prepending means CLI args come after in `@ARGV` — scalars get overwritten by CLI (natural GetOptions behavior), arrays accumulate from both sources.

### Phase 3: Output changes

1. Rename "options:" to "command-line options:"
2. Add "environment options:" line above (raw `LTL_CONFIG` string)
3. Extend `-V` output with merged configuration

### Phase 4: Documentation

1. Update `print_help()`
2. Update README.md

## Acceptance Criteria

- [ ] `-i`, `-e`, `-h`, `-tpa` are additive on the command line (multiple uses combine with OR)
- [ ] `LTL_CONFIG` environment variable is read and parsed at startup
- [ ] Scalar options: CLI overrides `LTL_CONFIG`
- [ ] Additive options: values combine from both sources
- [ ] Quoted arguments with spaces handled correctly
- [ ] "environment options:" line shown when `LTL_CONFIG` is set (raw string)
- [ ] "command-line options:" replaces old "options:" label
- [ ] `-V` output shows final merged values
- [ ] Empty or unset `LTL_CONFIG` has no effect
- [ ] Error messages indicate when invalid options come from `LTL_CONFIG`
- [ ] `print_help()` documents `LTL_CONFIG`
- [ ] README.md updated

## Edge Cases

- `LTL_CONFIG=""` — empty, no effect
- `LTL_CONFIG` with quoted args containing spaces — must parse correctly
- Invalid option in `LTL_CONFIG` — clear error indicating source
- Same scalar option in both sources — CLI wins
- Same additive pattern in both sources — duplicates are harmless (regex OR)
