#!/bin/bash
#
# compare-results.sh — Compare two benchmark TSV result files
# Usage: ./compare-results.sh <baseline.tsv> <current.tsv>
#
# Issue #56: Memory Baseline Profiling

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <baseline.tsv> <current.tsv>" >&2
    exit 1
fi

BASELINE="$1"
CURRENT="$2"

if [[ ! -f "$BASELINE" ]]; then
    echo "ERROR: Baseline file not found: $BASELINE" >&2
    exit 1
fi

if [[ ! -f "$CURRENT" ]]; then
    echo "ERROR: Current file not found: $CURRENT" >&2
    exit 1
fi

# Use awk to join and compare the two files
# Composite key: test_name + options + metric_type + metric_name
awk -F'\t' '
BEGIN {
    OFS = "\t"
    print "test_name", "options", "metric", "baseline", "current", "delta", "change%", "indicator"
}

# Skip headers
NR == FNR && FNR == 1 { next }
NR != FNR && FNR == 1 { next }

# First file (baseline) — skip non-numeric rows (version, FILES)
NR == FNR {
    key = $1 OFS $2 OFS $3 OFS $4
    # Only compare numeric values
    if ($5 + 0 == $5 && $5 != "") {
        baseline[key] = $5
        keys_order[++n] = key
        seen[key] = 1
    }
    next
}

# Second file (current)
{
    key = $1 OFS $2 OFS $3 OFS $4
    if ($5 + 0 == $5 && $5 != "") {
        current[key] = $5
        if (!(key in seen)) {
            keys_order[++n] = key
            seen[key] = 1
        }
    }
}

END {
    for (i = 1; i <= n; i++) {
        key = keys_order[i]
        split(key, parts, OFS)
        test = parts[1]
        opts = parts[2]
        metric = parts[3] "/" parts[4]

        b = (key in baseline) ? baseline[key] : "N/A"
        c = (key in current) ? current[key] : "N/A"

        if (b == "N/A" || c == "N/A") {
            delta = "N/A"
            pct = "N/A"
            ind = "?"
        } else {
            delta = c - b
            if (b != 0) {
                pct = sprintf("%.1f", (delta / b) * 100)
            } else if (c == 0) {
                pct = "0.0"
            } else {
                pct = "NEW"
            }

            # Indicator: timing/memory increases are regressions
            if (delta > 0) {
                ind = "REGRESS"
            } else if (delta < 0) {
                ind = "IMPROVE"
            } else {
                ind = "="
            }
        }

        # Skip rows where both values are 0 (uninteresting)
        if (b == 0 && c == 0) continue

        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", test, opts, metric, b, c, delta, pct, ind
    }
}
' "$BASELINE" "$CURRENT" | column -t -s$'\t'
