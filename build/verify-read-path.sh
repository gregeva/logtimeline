#!/usr/bin/env bash
#
# Proves a packaged ltl binary prepares the read path's generated body: with
# the threshold at 0, every file of the fixture must report the generated
# path. A binary that cannot write or compile the body still gives correct
# output on the standard path, only slower, so nothing else would catch it
# (features/621-generated-read-loop-body.md D5).
#
# Usage:
#   ./build/verify-read-path.sh <fixture> <command that runs the binary...>
#   e.g. ./build/verify-read-path.sh tests/fixtures/access-classification-buckets.txt ./ltl_static-binary_macos-arm64
#        ./build/verify-read-path.sh ../tests/fixtures/access-classification-buckets.txt wine ../ltl_static-binary_windows-amd64.exe

set -euo pipefail

fixture="$1"; shift
set +e
out=$("$@" --disable-progress -ni --generated-loop-threshold=0 -V read-path "$fixture" 2>&1)
rc=$?
set -e
out=$(printf '%s\n' "$out" | tr -d '\r')
if [[ $rc -ne 0 ]]; then
    echo "[error] read-path check: the binary exited $rc"
    printf '%s\n' "$out" | tail -5
    exit 1
fi
section=$(printf '%s\n' "$out" | sed -n '/^=== read-path ===$/,/^=== END read-path ===$/p')
if [[ -z "$section" ]]; then
    echo "[error] read-path check: the binary printed no -V read-path section"
    exit 1
fi
paths=$(printf '%s\n' "$section" | sed -n 's/^  path: //p')
text=$(printf '%s\n' "$section" | sed -n 's/^generated_text: //p')
if [[ -z "$paths" || "$text" != "written" ]] || printf '%s\n' "$paths" | grep -qv '^generated$'; then
    echo "[error] read-path check: the binary did not read the fixture with the generated body"
    printf '%s\n' "$section" | grep -v '^marker:'
    exit 1
fi
echo "[info] read-path check passed: the generated body was prepared and read the fixture"
