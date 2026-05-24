#!/usr/bin/env python3
"""
calculate-reference.py — Independent reference implementation of the
algebraically sensitive statistics (Decision 3) for Layer 3 of the
statistics test harness (Issue #224).

This script is the *oracle* that ltl is validated against. Its job is to
compute the same percentile / shape / variability statistics that ltl
emits, but using NumPy + SciPy with explicitly pinned methodology
parameters. The Perl comparison engine then joins ltl's CSV against the
JSON this script emits and tier-classifies any disagreement.

Phase F scope: Tomcat access logs only. Apache HTTP2, ThingWorx
ScriptLog, and Codebeamer formats are deferred to Issue #270; the
driver reports `L3=N/A` for those scenarios. The architecture is
format-agnostic — adding a new format is a matter of writing a new
parser function and dispatching on log shape.

Methodology pinning (per Decision 3):
  - Percentiles: numpy.percentile(samples, q, method='linear')
  - std_dev:     numpy.std(samples, ddof=1)             [Bessel-corrected]
  - cv:          std_dev / mean
  - skewness:    scipy.stats.skew(samples, bias=False)
  - kurtosis:    scipy.stats.kurtosis(samples, fisher=True, bias=False)
  - bimodality:  Sarle's bimodality coefficient (g1² + 1) / (g2 + 3(n-1)²/((n-2)(n-3)))

Each statistic's NumPy/SciPy call site name is surfaced in the emitted
JSON so the Perl engine can cite it verbatim in failure output (the
`produced_by` field). This is the contract Decision 3 establishes: when
L3 fires, the operator sees exactly which reference call ltl is being
held to.

CLI:
  calculate-reference.py
      --log <path>
      --bucket-size-seconds <N>
      [--duration-unit ms|us]            [default: ms]
      [--format tomcat-access]           [default: tomcat-access]

Output: JSON written to stdout. Top-level object:
  {
    "format": "tomcat-access",
    "bucket_size_seconds": 14400,
    "duration_unit": "ms",
    "rows": [
      {
        "category": "plain",
        "message":  "[200] POST /Thingworx/Things/.../GetDateAndTime",
        "bucket":   "2025-05-07 00:00",
        "occurrences": 155109,
        "stats": {
            "p1":     {"value": 0,     "produced_by": "numpy.percentile(samples, 1, method='linear')"},
            "p5":     {...},
            ...
            "std_dev": {"value": ..., "produced_by": "numpy.std(samples, ddof=1)"},
            "cv":      {"value": ..., "produced_by": "std_dev/mean (derived)"},
            "skewness":  {...},
            "kurtosis":  {...},
            "bimodality_coef": {...},
            "iqr":     {...}
        }
      },
      ...
    ]
  }
"""

import argparse
import json
import re
import sys
import time
from datetime import datetime, timezone

import math
import warnings

import numpy as np
from scipy import stats as scipy_stats

# SciPy emits RuntimeWarning when computing skew/kurtosis on nearly-
# identical samples (catastrophic cancellation in moment calculation).
# The result in those cases is NaN, which we surface as null in the
# emitted JSON. Suppress the warning so the oracle's stderr stays clean
# — the NaN itself is the diagnostic signal.
warnings.filterwarnings(
    "ignore",
    category=RuntimeWarning,
    message="Precision loss occurred in moment calculation",
)


def _finite_or_none(v):
    """Convert NaN/Inf to None so JSON serialization is clean."""
    if v is None:
        return None
    if isinstance(v, float) and not math.isfinite(v):
        return None
    return v

# ---------------------------------------------------------------------
# Tomcat access log parser — mirrors prototype/189-bin-counter-primitives.pl
# which itself mirrors prototype/96-fuzzy-consolidation.pl, which mirrors
# ltl's match_type 3 (production regex at ltl:6621).
# ---------------------------------------------------------------------

# Verbatim from prototype/189:
#   ^(.+? ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?
# Group 1: trailing junk (3 space-separated fields: IP, ident, user)
# Group 2: timestamp like "07/May/2025:00:00:00 +0000"
# Group 3: request line like "POST /url HTTP/1.1"
# Group 4: status code (200, 404, ...)
# Group 5: bytes (or "-")
# Group 6: duration (optional, in milliseconds for Tomcat)
# Group 7: thread (optional)
# Group 8: session (optional)
TOMCAT_REGEX = re.compile(
    r'^(?:.+? ){3}\[([^\]]+)\] "([^"]+)" (\d{3}) (\d+|-)(?:[ ]([0-9.]+))?(?:[ ](\S+))?(?:[ ](\S+))?'
)

# Tomcat timestamp format: "07/May/2025:00:00:00 +0000".
# We strip the timezone offset (ltl:6627), then parse the rest.
# ltl uses POSIX strftime/gmtime — same wall-clock interpretation as parse-as-naive.
TOMCAT_TS_FORMAT = "%d/%b/%Y:%H:%M:%S"


def parse_tomcat_line(line):
    """Parse one Tomcat access log line.

    Returns a tuple (epoch_seconds, category, message, duration) or None
    if the line does not match. Mirrors ltl:6621-6632 normalization
    rules: strip ' HTTP/N.N', strip '?query_string', '5xx'-bucket the
    status code into a category.
    """
    m = TOMCAT_REGEX.match(line)
    if not m:
        return None

    ts_str, request, status_str, _bytes_str, dur_str, _thread, _session = m.groups()

    # ltl:6627 — chop off timezone offset before parsing.
    # The format is "07/May/2025:00:00:00 +0000" → "07/May/2025:00:00:00".
    ts_no_tz = re.sub(r' [+-]\d{4}$', '', ts_str)
    try:
        dt = datetime.strptime(ts_no_tz, TOMCAT_TS_FORMAT)
    except ValueError:
        return None
    # Treat as UTC (ltl uses gmtime for output formatting; the offset was
    # explicitly chopped so this is equivalent to "interpret bare timestamp
    # as UTC"). For the bucket-size math, only the relative epoch matters.
    epoch = dt.replace(tzinfo=timezone.utc).timestamp()

    # ltl:6630-6631 — normalize the request: strip ' HTTP/N.N' and '?query'.
    msg = re.sub(r' HTTP/\d\.\d$', '', request)
    msg = re.sub(r'\?.+$', '', msg)

    status_code = status_str

    # ltl:6626 — bucket status code: 200 → 2xx, 404 → 4xx, etc.
    # category here is the HTTP family used by ltl for the level columns.
    # However, the MESSAGES CSV `category` is 'plain' or 'highlight', NOT
    # the HTTP family — that's a different thing. For row keying we use
    # the actual status code embedded in the message string.
    # We surface the level family as the bucket-side `level_family` so
    # the oracle can compute level counts if ever needed; for L3 stats
    # we only need the row key.
    level_family = re.sub(r'(\d)\d{2}', r'\1xx', status_code)

    # Row-key message = "[STATUS] METHOD /url" with no thread (the Tomcat
    # log file we test against does not record %I thread field, so the
    # thread group is empty and ltl emits the no-thread variant — see the
    # baselines/tomcat-default/messages.csv first column for confirmation).
    row_message = f"[{status_code}] {msg}"

    # Duration parse — must be a clean numeric literal (mirrors prototype/189
    # corruption guard). Tomcat logs duration in ms.
    duration = None
    if dur_str and re.fullmatch(r'\d+(?:\.\d+)?', dur_str):
        duration = float(dur_str)

    return (epoch, row_message, duration, level_family)


# ---------------------------------------------------------------------
# Bucketing — mirrors ltl:7008 exactly.
# ---------------------------------------------------------------------

def bucket_epoch(event_epoch, bucket_size_seconds):
    """Compute the bucket's start epoch (UTC, second-resolution).

    Mirrors ltl:7008: bucket = int(epoch / bucket_size) * bucket_size.
    """
    return int(event_epoch // bucket_size_seconds) * bucket_size_seconds


def bucket_label(bucket_epoch_value):
    """Format the bucket as ltl writes it in STATS CSV: '%Y-%m-%d %H:%M' UTC.

    Mirrors ltl:9591 (strftime + gmtime).
    """
    dt = datetime.fromtimestamp(bucket_epoch_value, tz=timezone.utc)
    return dt.strftime("%Y-%m-%d %H:%M")


# ---------------------------------------------------------------------
# Statistic computation — per Decision 3, methodology pinned.
# ---------------------------------------------------------------------

PERCENTILES = {
    "p1":      1.0,
    "p5":      5.0,
    "p10":     10.0,
    "p25":     25.0,
    "p50":     50.0,
    "p75":     75.0,
    "p90":     90.0,
    "p95":     95.0,
    "p99":     99.0,
    "p999":    99.9,
    "p9999":   99.99,
    "p99999":  99.999,
}


def compute_oracle_stats(samples):
    """Compute Decision-3 statistics for one sample list.

    Returns a dict {stat_name: {"value": v, "produced_by": "..."}} with
    one entry per Layer-3 statistic. Returns None for any statistic
    that is undefined for the given sample size (e.g., skewness needs
    n >= 3; bimodality_coef needs n >= 4).
    """
    if not samples:
        return {}
    arr = np.array(samples, dtype=float)
    n = arr.size

    out = {}

    # Percentiles — numpy.percentile with method='linear' (Decision 3 pin).
    for name, q in PERCENTILES.items():
        v = float(np.percentile(arr, q, method="linear"))
        out[name] = {
            "value": _finite_or_none(v),
            "produced_by": f"numpy.percentile(samples, {q}, method='linear')",
        }

    # IQR — same family as percentile, but Decision 4 also derives it as
    # p75 - p25. L3's job is to validate p25/p75 themselves; we still
    # emit iqr so the engine can cross-check.
    p75 = float(np.percentile(arr, 75.0, method="linear"))
    p25 = float(np.percentile(arr, 25.0, method="linear"))
    out["iqr"] = {
        "value": _finite_or_none(p75 - p25),
        "produced_by": "numpy.percentile(samples, 75, method='linear') - numpy.percentile(samples, 25, method='linear')",
    }

    # std_dev — Bessel-corrected (ddof=1) per Decision 3.
    if n >= 2:
        std = float(np.std(arr, ddof=1))
    else:
        std = 0.0
    out["std_dev"] = {
        "value": _finite_or_none(std),
        "produced_by": "numpy.std(samples, ddof=1)",
    }

    # mean (for cv derivation; not in Decision-3 directly but needed)
    mean = float(np.mean(arr))

    # cv — derived from std_dev/mean.
    if mean != 0.0:
        cv = std / mean
    else:
        cv = None
    out["cv"] = {
        "value": _finite_or_none(cv),
        "produced_by": "numpy.std(samples, ddof=1) / numpy.mean(samples)",
    }

    # Skewness — Fisher-style, bias-corrected (Decision 3).
    # Returns NaN under catastrophic-cancellation conditions; we surface
    # as null.
    if n >= 3:
        skew_raw = scipy_stats.skew(arr, bias=False)
        skew = _finite_or_none(float(skew_raw))
    else:
        skew = None
    out["skewness"] = {
        "value": skew,
        "produced_by": "scipy.stats.skew(samples, bias=False)",
    }

    # Kurtosis — Fisher (excess), bias-corrected.
    if n >= 4:
        kurt_raw = scipy_stats.kurtosis(arr, fisher=True, bias=False)
        kurt = _finite_or_none(float(kurt_raw))
    else:
        kurt = None
    out["kurtosis"] = {
        "value": kurt,
        "produced_by": "scipy.stats.kurtosis(samples, fisher=True, bias=False)",
    }

    # Bimodality coefficient — Sarle's formula:
    #   b = (g1^2 + 1) / (g2 + 3*(n-1)^2 / ((n-2)*(n-3)))
    # where g1 is sample skewness and g2 is sample excess kurtosis.
    # Undefined for n < 4 or when either input is NaN/None.
    if n >= 4 and skew is not None and kurt is not None:
        denom = kurt + 3.0 * (n - 1) ** 2 / ((n - 2) * (n - 3))
        if denom != 0.0:
            bc = _finite_or_none((skew ** 2 + 1.0) / denom)
        else:
            bc = None
    else:
        bc = None
    out["bimodality_coef"] = {
        "value": bc,
        "produced_by": "Sarle bimodality: (skew^2 + 1) / (kurtosis_excess + 3*(n-1)^2/((n-2)*(n-3)))",
    }

    return out


# ---------------------------------------------------------------------
# Main: parse log → partition by (row_key, bucket) → compute → emit JSON.
# ---------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="NumPy/SciPy reference oracle for Layer 3 (Issue #224).",
    )
    ap.add_argument("--log", required=True, help="Path to source log file")
    ap.add_argument("--bucket-size-seconds", type=int, required=True,
                    help="Bucket size in seconds (e.g. -bs 240 → 14400)")
    ap.add_argument("--duration-unit", default="ms", choices=("ms", "us"),
                    help="Input duration unit (default: ms)")
    ap.add_argument("--format", default="tomcat-access", choices=("tomcat-access",),
                    help="Log format. Phase F supports tomcat-access only; other formats deferred.")
    args = ap.parse_args()

    if args.format != "tomcat-access":
        print(f"ERROR: oracle does not yet support format '{args.format}'", file=sys.stderr)
        sys.exit(2)

    # Group samples by (row_key, bucket_epoch).
    # Key: (row_message, bucket_epoch). Value: list of durations.
    groups = {}

    t_start = time.time()
    lines_total = 0
    lines_parsed = 0
    lines_with_duration = 0

    with open(args.log, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            lines_total += 1
            parsed = parse_tomcat_line(line)
            if parsed is None:
                continue
            lines_parsed += 1
            epoch, row_message, duration, _level_family = parsed
            if duration is None:
                continue
            lines_with_duration += 1

            # ltl applies the duration-unit scaling at emission time (the
            # `min`/`mean`/`max`/percentile values are in the same unit
            # as the input field). For Tomcat the raw field is ms, and
            # -du us is not used (only Apache HTTP2 sets that). When
            # --duration-unit us is supplied, the oracle interprets the
            # raw field as microseconds — same as ltl.
            # For Tomcat scenarios in Phase F we always pass --duration-unit ms.

            be = bucket_epoch(epoch, args.bucket_size_seconds)
            key = (row_message, be)
            groups.setdefault(key, []).append(duration)

    t_parse = time.time() - t_start
    print(
        f"INFO oracle: format=tomcat-access lines_total={lines_total} "
        f"lines_parsed={lines_parsed} lines_with_duration={lines_with_duration} "
        f"unique_keys={len(groups)} parse_seconds={t_parse:.2f}",
        file=sys.stderr,
    )

    # Emit per-row JSON. Note: the engine joins on (category, message,
    # bucket). For MESSAGES CSV, ltl produces an aggregated row per
    # (category, message) without bucket — the category is 'plain' or
    # 'highlight' and the row is across all buckets. For STATS CSV, the
    # row is keyed by bucket only.
    #
    # In Phase F the oracle emits both views:
    #   1. Per-(row_message, bucket) for STATS-style validation (one
    #      bucket at a time).
    #   2. Aggregated across all buckets per row_message for MESSAGES-style
    #      validation.
    # The engine selects which to use based on --file-kind.

    rows_messages = []  # per-row, aggregated across buckets
    rows_stats = []     # per-(row_message, bucket)

    # Build per-row aggregation by row_message.
    per_message_samples = {}
    per_bucket_samples = {}  # for STATS, aggregated across all messages
    for (row_message, be), samples in groups.items():
        per_message_samples.setdefault(row_message, []).extend(samples)
        per_bucket_samples.setdefault(be, []).extend(samples)
        rows_stats.append({
            "category": "plain",   # placeholder; STATS does not use category
            "message":  row_message,
            "bucket":   bucket_label(be),
            "occurrences": len(samples),
            "stats":    compute_oracle_stats(samples),
        })

    # MESSAGES CSV: one row per (category, message) aggregated across buckets.
    # The CSV `category` field is 'plain' or 'highlight'. Tomcat scenarios
    # produce 'plain' for all rows (no highlight rules active by default).
    for row_message, samples in per_message_samples.items():
        rows_messages.append({
            "category": "plain",
            "message":  row_message,
            "bucket":   "",   # MESSAGES rows are not bucket-keyed
            "occurrences": len(samples),
            "stats":    compute_oracle_stats(samples),
        })

    # STATS CSV: one row per bucket, aggregated across all messages (the
    # bucket-wide totals). The above rows_stats are per-(message, bucket),
    # which is NOT what STATS CSV emits — STATS aggregates across messages.
    # Replace rows_stats with the correct per-bucket aggregation.
    rows_stats = []
    for be, samples in per_bucket_samples.items():
        rows_stats.append({
            "category": "",
            "message":  "",
            "bucket":   bucket_label(be),
            "occurrences": len(samples),
            "stats":    compute_oracle_stats(samples),
        })

    out = {
        "format":              args.format,
        "bucket_size_seconds": args.bucket_size_seconds,
        "duration_unit":       args.duration_unit,
        "lines_total":         lines_total,
        "lines_parsed":        lines_parsed,
        "lines_with_duration": lines_with_duration,
        "rows_messages":       rows_messages,
        "rows_stats":          rows_stats,
    }

    json.dump(out, sys.stdout, indent=None, separators=(",", ":"))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
