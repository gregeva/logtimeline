#!/usr/bin/env python3
"""Generate the duration-display render fixture: a small Tomcat access log
(match_type 3 shape, trailing %D in milliseconds) whose duration values are
chosen so every cell class the render invariants guard is present on both
rendered surfaces:

  - zero durations           -> the `0ms` zero-rendering rule
  - small integers (1, 58..) -> bare-number / fabricated-decimal rule (#292 bugs 1 and 2)
  - ~1 s values              -> auto-scale to a coarser unit keeps one decimal (1s, 1.4s)
  - multi-second values      -> 5.5s-class cells

Fully deterministic (round-robin, no RNG): the committed fixture is
reproducible byte-for-byte. Content is synthetic - TEST-NET addresses
(RFC 5737), generic entity names, no real hosts, users or paths.

Usage: generate-fixture.py <output-path>
"""
import sys
from datetime import datetime, timedelta

# (method, path, status pool, bytes pool, duration pool in ms)
ENDPOINTS = [
    ("POST", "/Thingworx/Metrics?x-thingworx-session=false",
        [200], [14305, 14290, 14310], [0, 0, 0, 1, 1, 2]),
    ("GET",  "/Thingworx/Things/SampleThing/Properties/Status",
        [200, 200, 304], [512, 0, 512], [0, 1, 1, 2, 3]),
    ("POST", "/Thingworx/Things/SampleThing/Services/GetDateAndTime",
        [200], [86, 86, 88], [58, 60, 62, 58, 166]),
    ("POST", "/Thingworx/Things/SampleDataTable/Services/QueryDataTableEntries",
        [200, 200, 200, 500], [20480, 40960, 81920, 212], [166, 180, 200, 999, 1002]),
    ("POST", "/Thingworx/Things/SampleStream/Services/QueryStreamEntriesWithData",
        [200], [102400, 204800, 409600], [1000, 1002, 1050, 1400, 5455]),
    ("GET",  "/Thingworx/Mashups/SampleDashboard",
        [200, 302], [65536, 0], [1, 58, 166, 1002, 5455]),
    ("POST", "/Thingworx/ThingTemplates/RemoteThing/Services/QueryImplementingThingsWithNamedData",
        [200], [5519, 5520, 5530], [6, 7, 8, 9, 10]),
    ("GET",  "/Thingworx/Composer/index.html",
        [200, 200, 404], [3072, 3072, 196], [12, 15, 20, 25, 30]),
    ("POST", "/Thingworx/Things/SampleTimer/Services/Trigger",
        [200], [0], [0, 0, 1, 0, 0]),
    ("GET",  "/Thingworx/health",
        [200], [2], [0, 0, 0, 0, 1]),
    ("POST", "/Thingworx/Things/SampleFileRepository/Services/GetFileListing",
        [200], [8192, 16384, 24576], [300, 450, 600, 750, 900]),
    ("GET",  "/Thingworx/Resources/Images/logo.png",
        [200, 304], [4096, 0], [2, 3, 4, 5, 6]),
]
HOSTS = ["192.0.2.10", "192.0.2.10", "192.0.2.11", "192.0.2.12", "127.0.0.1"]

START = datetime(2025, 5, 7, 0, 0, 0)
END = datetime(2025, 5, 7, 14, 27, 48)
STEP = timedelta(seconds=120)


def main(argv):
    if len(argv) != 2:
        sys.stderr.write("usage: generate-fixture.py <output-path>\n")
        return 2
    lines = []
    ts, i = START, 0
    while ts <= END:
        method, path, statuses, byte_pool, durations = ENDPOINTS[i % len(ENDPOINTS)]
        k = i // len(ENDPOINTS)
        lines.append(
            '%s - - [%s +0000] "%s %s HTTP/1.1" %d %d %d\n' % (
                HOSTS[i % len(HOSTS)],
                ts.strftime("%d/%b/%Y:%H:%M:%S"),
                method, path,
                statuses[k % len(statuses)],
                byte_pool[k % len(byte_pool)],
                durations[k % len(durations)],
            ))
        ts += STEP
        i += 1
    with open(argv[1], "w") as f:
        f.writelines(lines)
    sys.stderr.write("generated %d lines -> %s\n" % (len(lines), argv[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
