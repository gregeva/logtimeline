#!/usr/bin/env python3
"""Extract the real per-message duration streams behind each consolidated row.

The order-independence and canonical-grid probes were first run on generated
members. This produces the real thing: for one log, the duration samples of
every message key, grouped by the cluster that `ltl -g` actually put them in,
read from the grouping the tool itself published (`-V message-grouping`).

Parsing reuses the statistics oracle's verbatim parsers, so the durations are
the same ones the oracle checks ltl against -- not a second interpretation of
the format.

Output, one line per message key:

    <cluster-id>\t<key>\t<duration> <duration> ...

Usage:
    extract-real-groups.py <membership-capture> <logfile> <parser> > groups.tsv

where <parser> is one of: thingworx, tomcat, apache_http2, codebeamer.
"""
import sys, os, importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
ORACLE = os.path.join(HERE, '..', '..', 'tests', 'statistics-drift', 'oracle',
                      'calculate-reference.py')
spec = importlib.util.spec_from_file_location('oracle', ORACLE)
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)

PARSERS = {
    'thingworx':    oracle.parse_thingworx_scriptlog_line,
    'tomcat':       oracle.parse_tomcat_line,
    'apache_http2': oracle.parse_apache_http2_line,
    'codebeamer':   oracle.parse_codebeamer_line,
}

def main():
    membership_path, logfile, parser_name = sys.argv[1:4]
    parse = PARSERS[parser_name]

    # key -> cluster id, from the grouping ltl published.
    member_of, cluster_id = {}, {}
    current = None
    with open(membership_path, encoding='utf-8', errors='replace') as fh:
        for line in fh:
            line = line.rstrip('\n')
            if line.startswith('  cluster: '):
                current = line[len('  cluster: '):]
                cluster_id.setdefault(current, len(cluster_id))
            elif line.startswith('    member: ') and current is not None:
                member_of[line[len('    member: '):]] = cluster_id[current]

    streams = {}
    with open(logfile, encoding='utf-8', errors='replace') as fh:
        for line in fh:
            rec = parse(line)
            if not rec:
                continue
            _epoch, row_message, duration = rec[0], rec[1], rec[2]
            if duration is None or duration <= 0:
                continue
            streams.setdefault(row_message, []).append(duration)

    # Emit only keys the tool actually grouped; ungrouped keys are single
    # histograms and are not what these probes are about.
    emitted = 0
    for key, values in streams.items():
        cid = member_of.get(key)
        if cid is None:
            continue
        sys.stdout.write("%d\t%s\t%s\n" % (cid, key.replace('\t', ' '),
                                           ' '.join(repr(v) for v in values)))
        emitted += 1
    sys.stderr.write("extracted %d grouped message keys across %d clusters\n"
                     % (emitted, len(cluster_id)))

if __name__ == '__main__':
    main()
