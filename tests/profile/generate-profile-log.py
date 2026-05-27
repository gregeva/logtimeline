#!/usr/bin/env python3
"""
generate-profile-log.py — Synthetic month-long log generator for the
time-axis folding (--profile) harnesses (Issue #256).

Emits a Tomcat access log (ltl match_type 3) spanning one full calendar
month, with a fixed, known number of requests on each day at fixed hours.
Because the placement is purely calendar-driven (no randomness), the folded
buckets, the per-weekday sample totals, and the dropped-day counts are all
known a priori — the generator writes them to a manifest so the harnesses
assert against declared truth rather than hardcoded numbers.

A full calendar month is deliberate: weekdays occur an unequal number of
times (four or five), so the per-weekday totals differ. The manifest carries
the exact totals, so this realism costs the harness nothing.

Each request is one line at 09:00 and one at 14:00 UTC per day (two hits/day),
all sharing one URL so ltl collapses them into a single message key. The hours
are chosen so day-fold lands them in two distinct hourly buckets and the
14:00 row exercises the weekday-once-per-boundary suppression.

The month is January 2025 by default (31 days): its weekday counts are
unequal (Fri occurs five times, Sat and Sun four), so the four work-modes have
*distinct* expected dropped-day totals — workweek drops 16 (Sat+Sun), but
workweek-alt drops 18 (Fri+Sat). That distinctness is deliberate: a bug that
dropped the wrong day-set would still pass against a month where the two totals
coincide. Override with --year / --month for other spans.

Usage:
  generate-profile-log.py <output-log-path> [--year Y] [--month M]
                          [--manifest <path>]

Writes the log to <output-log-path>. With --manifest, writes a JSON manifest
of the placement (per-weekday counts, hours, totals, span); otherwise prints
the manifest to stdout. Requires only the Python standard library.

Exits non-zero with a diagnostic on any error (no silent failure).
"""

import calendar
import datetime as dt
import json
import os
import sys

# Hits placed on every day, at these UTC hours. One line per hour.
HITS_HOURS = (9, 14)
URL = "/api/profile"
LINE_FMT = ('10.0.0.1 - - [{ts}] "GET ' + URL + ' HTTP/1.1" 200 100 5\n')
TS_FMT = "%d/%b/%Y:%H:%M:%S +0000"

# Weekday index convention matches Python's date.weekday(): Mon=0 .. Sun=6.
WEEKDAY_NAMES = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")


def build(year, month):
    """Return (lines, manifest) for one calendar month."""
    days_in_month = calendar.monthrange(year, month)[1]
    per_weekday = {name: 0 for name in WEEKDAY_NAMES}
    lines = []

    for day in range(1, days_in_month + 1):
        d = dt.date(year, month, day)
        wd = WEEKDAY_NAMES[d.weekday()]
        for hour in HITS_HOURS:
            ts = dt.datetime(year, month, day, hour, 0, 0)
            lines.append(LINE_FMT.format(ts=ts.strftime(TS_FMT)))
            per_weekday[wd] += 1

    total = sum(per_weekday.values())
    # Work-week day sets, by the same Mon=0..Sun=6 convention the modes use.
    # workweek (default): Mon-Fri.  workweek-alt: Sun-Thu.
    weekend_default = per_weekday["Sat"] + per_weekday["Sun"]
    weekend_alt = per_weekday["Fri"] + per_weekday["Sat"]

    manifest = {
        "issue": 256,
        "year": year,
        "month": month,
        "span_days": days_in_month,
        "hits_hours": list(HITS_HOURS),
        "url": URL,
        "per_weekday": per_weekday,
        "total_lines": total,
        # Dropped vs included counts the harness asserts per profile mode.
        "expected": {
            "day":          {"included": total, "dropped": 0},
            "week":         {"included": total, "dropped": 0},
            "week-alt":     {"included": total, "dropped": 0},
            "workweek":     {"included": total - weekend_default, "dropped": weekend_default},
            "workweek-alt": {"included": total - weekend_alt,     "dropped": weekend_alt},
            "workday":      {"included": total - weekend_default, "dropped": weekend_default},
            "workday-alt":  {"included": total - weekend_alt,     "dropped": weekend_alt},
        },
    }
    return lines, manifest


def main(argv):
    args = argv[1:]
    if not args or args[0] in ("-h", "--help"):
        sys.stderr.write(__doc__)
        return 0 if args[:1] in (["-h"], ["--help"]) else 2

    out_path = args[0]
    year, month, manifest_path = 2025, 1, None
    i = 1
    while i < len(args):
        if args[i] == "--year":
            year = int(args[i + 1]); i += 2
        elif args[i] == "--month":
            month = int(args[i + 1]); i += 2
        elif args[i] == "--manifest":
            manifest_path = args[i + 1]; i += 2
        else:
            sys.stderr.write(f"ERROR: unknown argument: {args[i]}\n")
            return 2

    if not (1 <= month <= 12):
        sys.stderr.write(f"ERROR: month must be 1-12, got {month}\n")
        return 2

    lines, manifest = build(year, month)

    try:
        with open(out_path, "w") as f:
            f.writelines(lines)
    except OSError as e:
        sys.stderr.write(f"ERROR: cannot write {out_path}: {e}\n")
        return 1

    manifest_json = json.dumps(manifest, indent=2, sort_keys=True)
    if manifest_path:
        try:
            with open(manifest_path, "w") as f:
                f.write(manifest_json + "\n")
        except OSError as e:
            sys.stderr.write(f"ERROR: cannot write manifest {manifest_path}: {e}\n")
            return 1
    else:
        print(manifest_json)

    sys.stderr.write(
        f"generated {manifest['total_lines']} lines "
        f"({manifest['span_days']} days of {year}-{month:02d}) -> {out_path}\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
