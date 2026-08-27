#!/usr/bin/env bash
# Slice the two bytes accumulation blocks out of `ltl` verbatim so the baseline
# arm measures production code rather than a retyped copy of it (#58 F9).
#
# The #432 hot path is inline inside read_and_process_logs(), not a set of subs,
# so blocks are located by distinctive anchor text and their extent taken by
# brace depth. A missing anchor is a hard failure: a silently-empty extraction
# would leave the baseline arm measuring nothing.
#
# Writes /tmp/432-blocks.pl
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 - <<'PY'
import re

src = open('ltl').read().splitlines()

def find(anchor, start=0):
    for n in range(start, len(src)):
        if anchor in src[n]:
            return n
    raise SystemExit("ANCHOR NOT FOUND in ltl: %r" % anchor)

def block_from(n):
    """Take lines from n until brace depth returns to zero."""
    depth = 0
    j = n
    while True:
        depth += src[j].count('{') - src[j].count('}')
        if depth == 0:
            return '\n'.join(src[n:j+1])
        j += 1
        if j - n > 200:
            raise SystemExit("runaway block from line %d" % n)

out = []

# --- per-message: the bytes sum and the count family that is its template ---
# The bytes line is a bare statement, not a block; take it plus the count block
# that follows so the prototype can see the shape it must match.
n_bytes_msg = find('{total_bytes} += $bytes if defined $bytes;')
out.append("# ltl:%d — per-message bytes accumulation (production, verbatim)\n%s"
           % (n_bytes_msg + 1, src[n_bytes_msg]))

n_count_msg = find('if( defined $count ) {', n_bytes_msg)
out.append("# ltl:%d — per-message count family (production, verbatim; the template)\n%s"
           % (n_count_msg + 1, block_from(n_count_msg)))

# --- per-message entry initialiser, both -mdm models ---
n_init = find('$log_messages{$category}{$log_key} //= ($message_stats_capture_mode')
out.append("# ltl:%d — per-message entry initialiser, bin and raw branches (production, verbatim)\n%s"
           % (n_init + 1, block_from(n_init)))

# --- per-bucket: the bytes block and the count block below it ---
n_bytes_bkt = find('$log_analysis{$bucket}{total_bytes} += $bytes;')
# step back to the guard that opens the block
n_guard = n_bytes_bkt
while 'if( defined $bytes' not in src[n_guard]:
    n_guard -= 1
    if n_bytes_bkt - n_guard > 10:
        raise SystemExit("per-bucket bytes guard not found above line %d" % n_bytes_bkt)
out.append("# ltl:%d — per-bucket bytes accumulation (production, verbatim)\n%s"
           % (n_guard + 1, block_from(n_guard)))

n_count_bkt = find('$log_analysis{$bucket}{count_sum} += $count;')
while 'if( defined $count' not in src[n_count_bkt]:
    n_count_bkt -= 1
out.append("# ltl:%d — per-bucket count family (production, verbatim; the template)\n%s"
           % (n_count_bkt + 1, block_from(n_count_bkt)))

open('/tmp/432-blocks.pl', 'w').write(
    "# Extracted from ltl by prototype/432-bytes-parity/extract-blocks.sh\n"
    "# DO NOT EDIT — regenerate to pick up production changes.\n\n"
    + '\n\n'.join(out) + '\n')
print("wrote /tmp/432-blocks.pl (%d blocks)" % len(out))
PY
