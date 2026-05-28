#!/usr/bin/env bash
# cleanup-test-artifacts.sh — master end-of-suite cleanup.
#
# Removes the shared scratch directory tests/.artifacts/ used by the test
# harnesses for cross-harness artifact sharing (e.g., the CSV cache used
# by validate-csv-output.sh and validate-statistics.sh).
#
# Per-harness traps that delete the cache are forbidden because they would
# defeat cross-harness reuse. This is the only script in the test suite
# that deletes the shared cache.
#
# Invoked in two situations:
#   1. By an orchestrator (release-process step list, future master test
#      runner) after all harnesses in a chain have completed.
#   2. By each harness's `csv_cache_maybe_cleanup` at end of run iff
#      running standalone (CI env var unset).
#
# Future harnesses with their own shared scratch directories register
# themselves by extending this script — add another `rm -rf` line.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR/.artifacts"

if [[ -d "$ARTIFACTS_DIR" ]]; then
    rm -rf "$ARTIFACTS_DIR"
fi

exit 0
