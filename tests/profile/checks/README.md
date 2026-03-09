# Checks Files — Declarative Cross-Validation Tables

Each `.tsv` file in this directory maps NYTProf subroutine call counts to
expected values derived from ltl's internal `-V` verbose output, for a
specific feature or investigation context.

## Purpose

Cross-validation catches bugs that pure timing analysis misses: a function
called 10× more than expected may not be a bottleneck by time, but it reveals
an algorithmic or control-flow error. The check files make this validation
explicit, declarative, and repeatable.

## File Format

Tab-separated, one check per line. Lines starting with `#` are comments.

```
nytprof_sub <TAB> v_expression <TAB> tolerance <TAB> label <TAB> regex
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `nytprof_sub` | yes | Short subroutine name (without `main::`) as shown in NYTProf output |
| `v_expression` | yes | Counter key, sum expression (`key1+key2`), or literal integer |
| `tolerance` | yes | `N%` for percentage tolerance, or `exact` for exact match |
| `label` | yes | Human-readable description of this check |
| `regex` | no | Regex to extract counter from `-V` output. Include a capture group `(\d+)`. Prefix with `+` to sum all matches (e.g., per-category counters). |

### `v_expression` forms

- **Key name**: `fc_calls` — looks up `$v{fc_calls}`, which was populated by the regex column
- **Sum**: `s1_inline+s3_checkpoint` — adds `$v{s1_inline}` + `$v{s3_checkpoint}`
- **Literal integer**: `1` — expected exact call count (use with `exact` tolerance)

### Regex extraction

The regex is run against every line of the `-V` verbose output. The first
capture group `(\d+)` is the extracted value. If the regex is prefixed with
`+`, all matches are summed (for per-category counters that appear multiple
times in the output).

## Usage

```bash
/opt/homebrew/bin/perl tests/profile/extract-profile.pl \
    --file tests/profile/results/<label>/<sample>/nytprof.out \
    --verbose-file tests/profile/results/<label>/<sample>/verbose.txt \
    --checks-file tests/profile/checks/consolidation.tsv
```

## Adding a New Checks File

When profiling a new feature:

1. Identify which subroutines are hot (from NYTProf)
2. Add the corresponding flow counters to ltl's `-V` output for that feature
3. Create `checks/<feature>.tsv` mapping each subroutine to its counter
4. Document the regex used to extract each counter from the `-V` section

The checks file is part of the profile-ready contract. If a function you want
to validate doesn't have a counter in `-V`, add the instrumentation first.

See `features/nytprof-profiling-workflow.md` for the full contract.
