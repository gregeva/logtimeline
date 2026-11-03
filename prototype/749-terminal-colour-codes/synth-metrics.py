#!/usr/bin/env python3
"""synth-metrics.py <out.log>

A synthetic application log for showing every column colour beside its
heatmap: five hours of a log4j-style line every three seconds, each carrying
ten metrics named after the ten column colours in the order user-defined
metrics take them (blue first when no users or sessions column is drawn),
as name=value pairs.

- Each metric's values are log-normal around its own median, spread over
  about three decades, so a heatmap of it uses all eight gradient steps.
- The volume per 30-minute bucket stays within a fifth of the mean, so the
  metric columns' bars (sums per bucket) are comparable from row to row.
- In the buckets from 06:00 to 07:30, a third of the lines carry the token
  HL, so -h HL highlights a part of those rows' bars: each column's plain
  and highlighted fill side by side, while the other rows show the heatmap
  without highlight.

Deterministic (seeded): the same file every run.
"""
import math, random, sys
from datetime import datetime, timedelta

COLOURS = ["blue", "magenta", "red", "orange", "pink", "teal", "purple", "yellow", "green", "cyan"]
rng = random.Random(749)
medians = {c: 10 ** (2 + 0.25 * i) for i, c in enumerate(COLOURS)}
start = datetime(2026, 8, 21, 4, 0, 0)
out = open(sys.argv[1], "w", encoding="utf-8", newline="\n")
t = start
while t < start + timedelta(hours=5):
    bucket = (t - start).seconds // 1800
    if rng.random() < 0.9 + 0.1 * math.sin(bucket):
        hl = timedelta(hours=2) <= t - start < timedelta(hours=3, minutes=30) and rng.random() < 1 / 3
        values = ", ".join(f"{c}={rng.lognormvariate(math.log(medians[c]), 1.1):.0f}" for c in COLOURS)
        out.write(f"{t:%Y-%m-%d %H:%M:%S},{rng.randrange(1000):03d} INFO  [worker-{rng.randrange(8)}] "
                  f"com.example.Monitor  - {'HL ' if hl else ''}{values}\n")
    t += timedelta(seconds=3)
