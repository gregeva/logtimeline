#!/usr/bin/env bash
# Slice the five duration retention sites, the record-lexical declaration, the
# index block's numeric read and the demand gates out of `ltl` verbatim, so the
# prototype's baseline arm measures production code rather than a copy of it
# (prototype/README.md: "the baseline arm reproduces the production call
# structure, not just its logic"; "constants come from the source, not from
# memory"). Follows the pattern of prototype/459-order-independence/extract-subs.sh.
#
# Writes a Perl fragment to $1 (default /tmp/528-sites.pl) defining %SITES:
# one entry per production line, carrying the line verbatim and the `ltl` line
# number it came from, so a reader can check in one grep that the prototype's
# arms carry the lines `ltl` carries today. retained-representation.pl requires
# that fragment and asserts its own arm source against it.
#
# The five sites are enumerated in
# features/528-record-lexical-retained-representation.md § The retention sites,
# enumerated. If any of them stops matching exactly once, this script fails
# rather than emitting a silently shorter prototype.
#
# Two of the retention sites spill their `unless` condition onto a continuation
# line whose text also appears at unrelated sites (the consolidation-merge
# path), and the histogram condition's text appears again on the bin-streaming
# branch that takes no copy. Those three are therefore anchored to the line that
# must precede them rather than matched on their own text.
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT="${1:-/tmp/528-sites.pl}"

python3 - "$OUT" <<'PY'
import re, sys

out_path = sys.argv[1]
src = open('ltl').read().splitlines()

# (label, regex matching exactly one line of ltl, label of the line it must
# directly follow or None). The label names the site as the feature doc's
# § The retention sites, enumerated names it.
wanted = [
    ('record_lexicals',
     r'^my \( \$bytes, \$duration \);$', None),
    ('index_numeric_read',
     r'^\s+\$fd->\{duration_sum\} \+= \$duration;$', None),
    ('bucket_stats_demand_gate',
     r'^\s+if\( \$bucket_duration_stats_demand \) \{$', None),
    ('site1_bucket_durations_push',
     r'^\s+push @\{\$log_analysis\{\$bucket\}\{durations\}\}, \$duration$', None),
    ('site1_bucket_durations_cond',
     r"^\s+unless \$bucket_stats_capture_mode eq 'bin';$", 'site1_bucket_durations_push'),
    ('message_stats_demand_gate',
     r'^\s+if\( \$message_duration_stats_demand \) \{$', None),
    ('site2_message_durations_push',
     r'^\s+push @\{\$log_messages\{\$category\}\{\$log_key\}\{durations\}\}, \$duration$', None),
    ('site2_message_durations_cond',
     r"^\s+unless \$message_stats_capture_mode eq 'bin';\s*$", 'site2_message_durations_push'),
    ('site3_first_sample_store',
     r"^\s+\$stats_source->\{durations\} = \[\$duration\] unless \$message_stats_capture_mode eq 'bin';$", None),
    ('site4_histogram_push',
     r'^\s+push @\{\$histogram_values\{duration\}\}, \$duration;$', None),
    ('site5_histogram_hl_push',
     r'^\s+push @\{\$histogram_values_hl\{duration\}\}, \$duration if \$is_highlighted;$',
     'site4_histogram_push'),
    ('duration_from_unit_token_transform',
     r'^\s+duration_from_unit_token => q\{.*\},$', None),
    # The recognition patterns of the two access-family shapes the prototype
    # reads: the integer-millisecond shape the timed corpus binds, and the
    # fractional-millisecond thread-session shape the correctness-only arm
    # binds. Sliced rather than restated so the prototype's extraction cannot
    # drift from the registry's.
    ('pattern_access_common_duration',
     r"^\s+pattern_src => '\^\(\[\^ \]\+\) \(\[\^ \]\+\) \(\[\^ \]\+\) \[\\\[\]\(\[\^\\\]\]\+\)\[\\\]\] \"\(\[\^\"\]\+\)\" \(\\d\{3\}\) \(\\d\+\|-\) \(\[0-9\.\]\+\)\$',$",
     None),
    ('pattern_access_common_duration_thread_session',
     r"^\s+pattern_src => '\^\(\[\^ \]\+\) \(\[\^ \]\+\) \(\[\^ \]\+\) \[\\\[\]\(\[\^\\\]\]\+\)\[\\\]\] \"\(\[\^\"\]\+\)\" \(\\d\{3\}\) \(\\d\+\|-\) \(\[0-9\.\]\+\) \(\\S\+\) \(\\S\+\)\$',$",
     None),
]

found = {}
problems = []
for label, pat, follows in wanted:
    rx = re.compile(pat)
    hits = [(n + 1, l.strip()) for n, l in enumerate(src) if rx.match(l)]
    if follows is not None:
        if follows not in found:
            problems.append("%s: its anchor %s was not resolved" % (label, follows))
            continue
        anchor_line = found[follows][0]
        hits = [h for h in hits if h[0] == anchor_line + 1]
    if len(hits) != 1:
        problems.append("%s: matched %d lines in ltl (expected exactly 1)" % (label, len(hits)))
        continue
    found[label] = hits[0]

# The histogram condition guarding sites 4 and 5: matched by text, then
# narrowed to the occurrence that precedes the raw push rather than the
# bin-streaming branch's counter_update, which takes no copy.
hist_cond_rx = re.compile(
    r'^\s+if \(\(!%histogram_metrics \|\| \$histogram_metrics\{duration\}\) && defined \$duration'
    r' && \$duration > 0 && !\$omit_durations\) \{$')
if 'site4_histogram_push' in found:
    push_line = found['site4_histogram_push'][0]
    hits = [(n + 1, l.strip()) for n, l in enumerate(src)
            if hist_cond_rx.match(l) and (n + 1) == push_line - 1]
    if len(hits) != 1:
        problems.append("site45_histogram_cond: matched %d lines directly above the raw push"
                        " (expected exactly 1)" % len(hits))
    else:
        found['site45_histogram_cond'] = hits[0]

if problems:
    raise SystemExit("extract-sites.sh: ltl has moved under this prototype:\n  " +
                     "\n  ".join(problems))

order = [w[0] for w in wanted]
order.insert(order.index('site4_histogram_push'), 'site45_histogram_cond')


def perl_q(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


lines = [
    "# Sliced out of `ltl` by",
    "# prototype/528-record-lexical-retained-representation/extract-sites.sh.",
    "# Do not edit: regenerate. Each entry is the production line verbatim, with",
    "# the `ltl` line number it was taken from at the time of the slice.",
    "our %SITES = (",
]
for label in order:
    n, text = found[label]
    lines.append("    '%s' => { ltl_line => %d, src => %s }," % (label, n, perl_q(text)))
lines.append(");")
lines.append("1;")

open(out_path, 'w').write("\n".join(lines) + "\n")
print("wrote %s (%d production lines sliced from ltl)" % (out_path, len(order)))
for label in order:
    n, text = found[label]
    print("  ltl:%-6d %s" % (n, text))
PY
