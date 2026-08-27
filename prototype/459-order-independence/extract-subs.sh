#!/usr/bin/env bash
# Slice the combination path's subs out of `ltl` verbatim so the probe measures
# production code rather than a copy of it. Writes /tmp/459-subs.pl.
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 - <<'PY'
import re
src = open('ltl').read().splitlines()
want = ['partition_new','partition_extend','partition_rebin','bin_assign','bin_boundary',
        'counter_entry_new','counter_entry_observe','merge_bin_counter_entries',
        'collapse_bin_counter_entry','percentile']
starts = {}
for n, l in enumerate(src):
    m = re.match(r'^sub (\w+) \{', l)
    if m and m.group(1) in want:
        starts[m.group(1)] = n
missing = [w for w in want if w not in starts]
if missing:
    raise SystemExit("subs not found in ltl: %s" % missing)
out = []
for name in want:
    n = starts[name]
    depth = 0
    j = n
    while True:
        depth += src[j].count('{') - src[j].count('}')
        if depth == 0:
            break
        j += 1
    out.append('\n'.join(src[n:j+1]))
open('/tmp/459-subs.pl', 'w').write('\n\n'.join(out) + '\n')
print("wrote /tmp/459-subs.pl (%d subs)" % len(want))
PY
