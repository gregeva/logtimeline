#!/usr/bin/env bash
# Slice the candidate-search path out of `ltl` verbatim so the probe measures
# production code, and derive the threshold-sized arm from the same text by
# changing only Phase 1's probe length and required hits.
#   usage: extract-subs.sh <output .pl>
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 - "$1" <<'PY'
import re, sys
out_path = sys.argv[1]
src = open('ltl').read().splitlines()

consts = ['consolidation_message_length_cap', 'consolidation_discriminative_topk',
          'consolidation_prefilter_ratio', 'uuid_re']
const_lines = []
for name in consts:
    hits = [l for l in src if re.match(r'^my \$%s\s*=' % name, l)]
    if len(hits) != 1:
        raise SystemExit("constant $%s: %d declarations found in ltl" % (name, len(hits)))
    const_lines.append(re.sub(r'^my ', 'our ', hits[0]))

want = ['get_consolidation_trigrams', 'dice_coefficient',
        'build_consolidation_ngram_index', 'find_consolidation_candidates']
subs = {}
for n, l in enumerate(src):
    m = re.match(r'^sub (\w+) \{', l)
    if m and m.group(1) in want:
        depth, j = 0, n
        while True:
            depth += src[j].count('{') - src[j].count('}')
            if depth == 0:
                break
            j += 1
        subs[m.group(1)] = '\n'.join(src[n:j + 1])
missing = [w for w in want if w not in subs]
if missing:
    raise SystemExit("subs not found in ltl: %s" % missing)

# Threshold-sized arm: probe the |r| - ceil(lb) + 1 rarest trigrams, lb = T*|r|/(200-T)
# in integer arithmetic, and admit a candidate on one shared trigram.
adaptive = subs['find_consolidation_candidates']
edits = [
    ('sub find_consolidation_candidates {', 'sub find_consolidation_candidates_sized {'),
    ('my $topk_actual = min($consolidation_discriminative_topk, scalar @disc_trigrams);',
     'my $topk_actual = min(max(1, $source_size - int(($source_size * $threshold_pct + (200 - $threshold_pct) - 1) / (200 - $threshold_pct)) + 1), scalar @disc_trigrams);'),
    ('my $loose_min = max(1, int($consolidation_prefilter_ratio * $topk_actual));',
     'my $loose_min = 1;'),
]
for old, new in edits:
    if adaptive.count(old) != 1:
        raise SystemExit("threshold-sized arm: expected one occurrence of: %s" % old)
    adaptive = adaptive.replace(old, new)

body = ['use List::Util qw(min max);', ''] + const_lines + [''] + [subs[w] for w in want] + [adaptive, '1;']
open(out_path, 'w').write('\n\n'.join(body) + '\n')
print("wrote %s (%d subs, threshold-sized arm derived)" % (out_path, len(want)))
PY
