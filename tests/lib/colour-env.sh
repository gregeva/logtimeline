#!/usr/bin/env bash
# colour-env.sh — shared ambient-colour-environment guard for test harnesses
# (tests/HARNESS-DESIGN.md § Colour rendering is controlled, never inherited,
# issue #438).
#
# `ltl` decides whether to emit ANSI from two environment variables, checked
# in this precedence order by help_ansi_enabled():
#
#     FORCE_COLOR (npm/chalk convention)  -> ANSI on
#     NO_COLOR    (no-color.org)          -> ANSI off
#     -t STDOUT                           -> ANSI iff stdout is a terminal
#
# That precedence is deliberate and is not what this library changes. The
# problem it solves is that a harness inherits both variables from whatever
# shell launched it, so the output it asserts against depends on the
# operator's terminal rather than on the scenario. A harness asserting on
# plain text with `NO_COLOR=1 "$LTL" ...` gets ANSI anyway when the launching
# environment exports FORCE_COLOR — the assertion silently tests precedence
# it never meant to test, and the same commit is green or red depending on
# who ran it.
#
# The guard: neutralise both variables at harness start, so the harness
# begins from the documented non-TTY default (ANSI off) regardless of the
# launching shell. A scenario that cares about colour then sets BOTH sides
# explicitly via the helpers below, never just the one it is naming.
#
# Public interface:
#   neutralize_colour_env
#       Unsets FORCE_COLOR and NO_COLOR in the harness's own environment.
#       Called once at harness start, before any ltl invocation.
#
#   with_ascii_colour CMD [ARG...]
#       Runs CMD with NO_COLOR=1 and FORCE_COLOR removed — ANSI off.
#
#   with_ansi_colour CMD [ARG...]
#       Runs CMD with FORCE_COLOR=1 and NO_COLOR removed — ANSI on.
#
# Both helpers set the full pair, so neither depends on the ambient state
# having been neutralised first; the assertion means the same thing whether
# the harness is run from a bare shell, a CI runner, or a colour-forcing
# terminal.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: colour-env.sh is a library; source it, do not execute it." >&2
    exit 2
fi

# Remove both colour variables from the harness's environment, so every
# ltl invocation that does not explicitly ask for a colour mode renders in
# the non-TTY default. Safe under `set -u`: `unset` on an unset name is a
# no-op and does not error.
neutralize_colour_env() {
    unset FORCE_COLOR
    unset NO_COLOR
    return 0
}

# Run a command with ANSI rendering forced OFF (both sides pinned).
with_ascii_colour() {
    NO_COLOR=1 env -u FORCE_COLOR "$@"
}

# Run a command with ANSI rendering forced ON (both sides pinned).
with_ansi_colour() {
    FORCE_COLOR=1 env -u NO_COLOR "$@"
}
