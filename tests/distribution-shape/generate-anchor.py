#!/usr/bin/env python3
"""
generate-anchor.py — Synthetic known-shape log generator for the
distribution-shape harness (Issue #254).

Emits a Tomcat access log (ltl match_type 3) whose per-request service
times follow a named distribution with known analytic shape. Every line
carries the same request URL, so ltl collapses all samples into a single
message key — one MESSAGES-CSV row whose skewness / kurtosis /
bimodality_coef columns characterize the whole distribution.

The RNG is seeded from a fixed constant so a given anchor produces a
byte-identical log on every run; this is what lets the harness assert
against fixed tolerance bands rather than re-deriving expectations.

Shape statistics (skewness, kurtosis, bimodality coefficient) are
scale-invariant, so the exponential anchor is scaled into a realistic
latency range without changing its expected shape.

Usage:
  generate-anchor.py <anchor> <output-log-path>

Anchors:
  normal       N(100, 10),  n=10000          -> skew~0,   exkurt~0,   BC<0.555
  exponential  Exp(1)*100,  n=200000         -> skew~2.0, exkurt~6.0, BC<0.555
  bimodal      N(50,5) + N(500,50), n=2000   -> two modes;            BC>0.555

Requires numpy. Exits non-zero with a diagnostic on any error (no silent
failure): unknown anchor, unwritable path, or missing numpy.
"""

import os
import sys

SEED = 20254

# Anchor definitions are the single source of truth for sample shape. The
# harness's tolerance bands are derived from these parameters; changing a
# parameter here is a breaking change to the harness and requires updating
# the corresponding band in tests/validate-distribution-shape.sh.
ANCHORS = ("normal", "exponential", "bimodal")


def draw(anchor, rng):
    import numpy as np

    if anchor == "normal":
        return rng.normal(100.0, 10.0, 10000)
    if anchor == "exponential":
        # Exp(lambda=1) has skew=2, excess kurtosis=6 regardless of scale;
        # *100 lifts the mean to ~100ms so the log reads like real latency.
        return rng.exponential(1.0, 200000) * 100.0
    if anchor == "bimodal":
        return np.concatenate([
            rng.normal(50.0, 5.0, 1000),
            rng.normal(500.0, 50.0, 1000),
        ])
    raise ValueError(f"unknown anchor: {anchor!r} (expected one of {', '.join(ANCHORS)})")


def main(argv):
    if len(argv) != 3:
        sys.stderr.write(f"usage: {os.path.basename(argv[0])} <anchor> <output-log-path>\n")
        sys.stderr.write(f"       anchor one of: {', '.join(ANCHORS)}\n")
        return 2

    anchor, out_path = argv[1], argv[2]

    try:
        import numpy as np
    except ImportError:
        sys.stderr.write("ERROR: generate-anchor.py requires numpy.\n")
        sys.stderr.write("       macOS:  brew install python && pip3 install numpy\n")
        sys.stderr.write("       Ubuntu: sudo apt-get install python3-numpy\n")
        return 1

    rng = np.random.default_rng(SEED)
    try:
        samples = draw(anchor, rng)
    except ValueError as e:
        sys.stderr.write(f"ERROR: {e}\n")
        return 2

    # match_type 3 line shape (ltl read_and_process_logs):
    #   <ip> - - [<ts>] "GET <url> HTTP/1.1" <status> <bytes> <duration>
    # ltl extracts the trailing duration field as %D. Decimals are
    # preserved by ltl's regex, so no integer quantization of the draws.
    line_fmt = ('1.2.3.4 - - [02/Feb/2025:00:00:11 +0000] '
                '"GET /api/{anchor} HTTP/1.1" 200 1000 {dur:.4f}\n')
    try:
        with open(out_path, "w") as f:
            for d in samples:
                # ltl gates duration capture on duration > 0; floor tiny/zero
                # draws (exponential left tail) to a small positive value.
                dur = d if d > 0 else 0.0001
                f.write(line_fmt.format(anchor=anchor, dur=dur))
    except OSError as e:
        sys.stderr.write(f"ERROR: cannot write {out_path}: {e}\n")
        return 1

    sys.stderr.write(f"generated {len(samples)} {anchor} samples -> {out_path}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
