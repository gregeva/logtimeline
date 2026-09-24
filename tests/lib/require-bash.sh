#!/usr/bin/env bash
# require-bash.sh — test scripts run under bash 4 or later, never macOS's
# /bin/bash 3.2.
#
# Under bash 3.2, a script running with set -e and set -u that dies on an
# unbound variable exits with its EXIT trap's own status: 0 once the trap's
# cleanup succeeds, and $? reads 0 inside the trap as well. Every harness
# cleans up through an EXIT trap, so under bash 3.2 a harness that crashes
# reports a pass. Bash 5 exits 1. Homebrew bash is installed by
# build/macos-setup.sh and must come first on PATH, as Homebrew Perl does.
#
# Sourced by tests/lib/scenario-select.sh, which every harness sources, and by
# tests/capture-regression.sh.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: require-bash.sh is a library; source it, do not execute it." >&2
    exit 2
fi

if (( BASH_VERSINFO[0] < 4 )); then
    echo "ERROR: $(basename "$0") needs bash 4 or later; it is running under bash $BASH_VERSION ($BASH)." >&2
    echo "       Install Homebrew bash (build/macos-setup.sh) and put \$(brew --prefix)/bin first on PATH." >&2
    exit 2
fi
