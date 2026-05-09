#!/usr/bin/env bash
# One-time bootstrap: activate the tracked pre-commit hook for this clone.
# Run from repo root: ./build/setup-hooks.sh

set -euo pipefail

if [ ! -d .githooks ]; then
    echo "[error] .githooks/ not found — are you in the repo root?" >&2
    exit 1
fi

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
echo "[ok] core.hooksPath set to .githooks"
echo "[ok] Pre-commit hook active. Override with --no-verify if you must."
