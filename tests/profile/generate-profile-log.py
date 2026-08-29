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

Each day emits hits at 09:00 and 14:00 UTC; at each hour one line per entry in
DURATIONS (a fixed, varied duration/bytes spread), all sharing one URL so ltl
collapses them into a single message key. The varied durations give each folded
bucket non-zero variance so the shape statistics are defined. The two hours are
chosen so day-fold lands them in two distinct hourly buckets and the 14:00 rows
exercise the weekday-once-per-boundary suppression. Per-weekday and total counts
are computed and written to the manifest, so consumers never hardcode them.

The month is January 2025 by default (31 days): its weekday counts are
unequal (Fri occurs five times, Sat and Sun four), so a mode and its -alt form
have *distinct* expected day totals — the default calendar's weekend pair
(Sat+Sun) and the Sunday-anchored one's (Fri+Sat) differ. That distinctness is
deliberate: a bug that used the wrong day-set would still pass against a month
where the two totals coincide. It separates both the modes that drop that pair
(the work and weekday modes) and the ones that keep it (the weekend modes).
Override with --year / --month for other spans.

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

# Hits placed on every day, at these UTC hours. Each hour emits several lines
# (one per duration in DURATIONS) so a folded bucket accumulates enough samples
# with non-zero variance for the shape statistics (skewness/kurtosis/bimodality)
# to be defined, not just min/mean/max.
HITS_HOURS = (9, 14)
URL = "/api/profile"
# A fixed, deterministic duration spread (milliseconds). Right-skewed with a
# couple of tail values so skewness/kurtosis are non-trivial and bimodality_coef
# is well-defined; same set on every hit so the fold is reproducible without an
# RNG. Each value also lands in a distinct bytes bucket via BYTES below.
DURATIONS = (3, 4, 5, 6, 8, 11, 17, 42)
BYTES = (100, 250, 500, 900, 1500, 3000, 7000, 22000)
LINE_FMT = ('10.0.0.1 - - [{ts}] "GET ' + URL + ' HTTP/1.1" 200 {bytes} {dur}\n')
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
            for dur, byts in zip(DURATIONS, BYTES):
                lines.append(LINE_FMT.format(ts=ts.strftime(TS_FMT), bytes=byts, dur=dur))
                per_weekday[wd] += 1

    total = sum(per_weekday.values())
    # The weekend pair under each calendar convention, by the same
    # Mon=0..Sun=6 convention the modes use: Sat+Sun by default, Fri+Sat under
    # the Sunday-anchored -alt calendar. The work and weekday modes drop this
    # pair (keeping Mon-Fri / Sun-Thu); the weekend modes keep exactly it.
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
        # The weekday modes keep the same days as their work counterparts; the
        # weekend modes keep exactly the days those drop, so their included and
        # dropped counts are the same two numbers the other way round.
        "expected": {
            "day":           {"included": total, "dropped": 0},
            "week":          {"included": total, "dropped": 0},
            "week-alt":      {"included": total, "dropped": 0},
            "workweek":      {"included": total - weekend_default, "dropped": weekend_default},
            "workweek-alt":  {"included": total - weekend_alt,     "dropped": weekend_alt},
            "workday":       {"included": total - weekend_default, "dropped": weekend_default},
            "workday-alt":   {"included": total - weekend_alt,     "dropped": weekend_alt},
            "weekdays":      {"included": total - weekend_default, "dropped": weekend_default},
            "weekdays-alt":  {"included": total - weekend_alt,     "dropped": weekend_alt},
            "weekday":       {"included": total - weekend_default, "dropped": weekend_default},
            "weekday-alt":   {"included": total - weekend_alt,     "dropped": weekend_alt},
            "weekends":      {"included": weekend_default, "dropped": total - weekend_default},
            "weekends-alt":  {"included": weekend_alt,     "dropped": total - weekend_alt},
            "weekend":       {"included": weekend_default, "dropped": total - weekend_default},
            "weekend-alt":   {"included": weekend_alt,     "dropped": total - weekend_alt},
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
