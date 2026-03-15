# Profiling Hypothesis: #135 Redundant Processing in Consolidation

## Problem
`-g 85` on XL access log data causes +41% memory and +58% time regression vs without `-g`.

## Hypothesis

The time regression is driven by three redundant processing patterns:

### 1. O(all_keys) cleanup loops (highest expected impact)
`run_consolidation_checkpoint` lines 2465-2487 iterate ALL keys in `%log_messages{$category}` and ALL keys in `%consolidation_key_trigrams` after every checkpoint to find which keys were absorbed. On XL data with 707K unique keys and multiple checkpoints, this is O(N * checkpoints) when it should be O(absorbed * checkpoints).

**Expected:** `cleanup_keys_scanned` will be orders of magnitude larger than actual absorbed keys.

### 2. S3 checkpoint re-testing (medium expected impact)
S3 (Gate 2) in `run_consolidation_pass` calls `match_consolidation_patterns` for every discovery candidate. These keys already failed S1 inline matching during parsing. S3 is only useful if NEW patterns were discovered since the key entered the unmatched set.

**Expected:** `s3_calls` will be large with near-zero `s3_checkpoint` match rate, especially on first checkpoint where no prior patterns exist.

### 3. `find_consolidation_candidates` on diverse data (known from prior investigation)
On diverse access logs (80% unique ratio), Dice similarity scoring examines many candidate pairs without finding matches. Each checkpoint fires `find_consolidation_candidates` up to 500 times.

**Expected:** `fc_calls` will be large relative to patterns discovered. NYTProf will show `find_consolidation_candidates` and `dice_coefficient` dominating exclusive time.

## Sample size plan
- Start at 10k (1k too small — checkpoint trigger is 5000, needs enough unique keys to fire)
- Scale to 100k if 10k confirms the pattern

## Test file
`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (277 MB, high diversity access log)

## Cross-validation
Use fixed `tests/profile/checks/consolidation.tsv` to validate:
- `match_consolidation_patterns` NYTProf calls = `keys_seen + s3_calls` (within 5%)
- `find_consolidation_candidates` NYTProf calls = `fc_calls` (within 5%)
