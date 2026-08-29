#!/usr/bin/env bash
# Slice the format-registry code the #453 classification prototype runs on
# out of `ltl` verbatim, so the baseline arm is the production generated
# block (format_entry_block_src + format_guard_cond_src, the transforms
# table, the specs, the timestamp cache) and not a copy of it. Writes the
# slice to the path given as $1 (default /tmp/453-slice.pl). The driver
# (453-classify-mini.pl) is concatenated after the slice so the generated
# source it evals sees the same file-scoped record lexicals `ltl` uses.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-/tmp/453-slice.pl}"
python3 - "$OUT" <<'PY'
import re, sys
out_path = sys.argv[1]
src = open('ltl').read().splitlines()

def find_line(pattern):
    for n, l in enumerate(src):
        if re.match(pattern, l):
            return n
    raise SystemExit("line not found in ltl: %s" % pattern)

def slice_block(start_pattern, end_pattern=None):
    """Return lines from the first match of start_pattern through the first
    line at/after it matching end_pattern (or the same line when None)."""
    n = find_line(start_pattern)
    if end_pattern is None:
        return src[n:n+1]
    j = n
    while not re.match(end_pattern, src[j]):
        j += 1
    return src[n:j+1]

def slice_sub(name):
    # ltl closes every sub with `}` at column 0; brace counting is not
    # reliable here (regex sources carry unbalanced literal braces).
    n = find_line(r'^sub %s \{' % re.escape(name))
    j = n + 1
    while src[j] != '}':
        j += 1
    return src[n:j+1]

parts = []
parts.append(['# ---- sliced from ltl by prototype/453-extract-slice.sh; do not edit ----'])
parts.append(slice_block(r'^my %timestamp_date_cache;'))
parts.append(slice_block(r'^my %timestamp_date_cache_added;'))
parts.append(slice_block(r'^my \$timestamp_date_cache_stamp = 0;'))
parts.append(slice_block(r'^use constant TIMESTAMP_DATE_CACHE_MAX'))
parts.append(slice_block(r'^my @format_record_fields = qw\(', r'.*\);\s*$'))
parts.append(slice_block(r'^my \( \$timestamp_str, \$category_bucket,'))
parts.append(slice_block(r'^my \( \$bytes, \$duration \);'))
parts.append(slice_block(r'^my \( \$status_code, \$is_access_log \);'))
parts.append(slice_block(r'^my \( \$timestamp, \$fractional_ms \);'))
parts.append(slice_block(r'^my \( \$format_last_ts_str, \$format_last_ts_epoch \)'))
parts.append(slice_block(r'^my \$format_scan_sub;'))
parts.append(slice_block(r'^my %wgm_msgtype_names = \(', r'^\);'))
parts.append(slice_block(r'^my %format_transform_code = \(', r'^\);'))
parts.append(slice_block(r'^my %format_month_map = \('))
for name in ['format_registry_specs', 'timestamp_date_cache_add', 'timestamp_date_cache_clear',
             'format_entry_block_src', 'format_guard_cond_src', 'convert_bytes']:
    parts.append(slice_sub(name))
parts.append(['# ---- end of slice ----'])
open(out_path, 'w').write('\n\n'.join('\n'.join(p) for p in parts) + '\n')
print("wrote %s (%d parts)" % (out_path, len(parts)))
PY
