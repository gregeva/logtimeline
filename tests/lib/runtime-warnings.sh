#!/usr/bin/env bash
# runtime-warnings.sh — shared runtime-warning cleanliness check for test
# harnesses (tests/HARNESS-DESIGN.md § Runtime-warning cleanliness, issue #341).
#
# A Perl runtime warning on ltl's stderr (uninitialized value, substr outside
# of string, non-numeric argument, ...) is an unguarded data path — a bug that
# has not yet found the input that makes it fatal or wrong. Interpreter-emitted
# warnings always carry the suffix ` at <file> line <N>`; intentional ltl
# diagnostics printed to stderr never do, so the pattern separates the two.
#
# Public function:
#   assert_no_runtime_warnings STDERR_FILE CONTEXT_LABEL
#       Returns 0 when the capture exists and is warning-free.
#       Prints the standardized self-documenting failure block (deduplicated
#       warning lines plus asserts/produced_by/contract) to stderr and
#       returns 1 otherwise. The CALLER decides what a failure means in its
#       own accounting (per-scenario counter, hard exit, ...).
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: runtime-warnings.sh is a library; source it, do not execute it." >&2
    exit 2
fi

assert_no_runtime_warnings() {
    local stderr_file="$1"
    local context="${2:-unlabeled-invocation}"

    # A missing capture is a harness defect, not a pass: it means an ltl
    # invocation ran without its stderr being captured at all.
    if [[ ! -e "$stderr_file" ]]; then
        {
            echo "FAIL  $context :: runtime-warning check has no stderr capture"
            echo "        expected capture: $stderr_file"
            echo "        asserts:     every ltl invocation captures stderr so it can be inspected for Perl runtime warnings"
            echo "        produced_by: the invoking harness (capture step)"
            echo "        contract:    tests/HARNESS-DESIGN.md section Runtime-warning cleanliness"
        } >&2
        return 1
    fi

    if grep -qE ' at .+ line [0-9]+' "$stderr_file"; then
        {
            echo "FAIL  $context :: perl-runtime-warnings-on-stderr"
            grep -E ' at .+ line [0-9]+' "$stderr_file" | sort | uniq -c | sort -rn | head -5 | sed 's/^/        /'
            echo "        asserts:     the run emits no Perl runtime warnings (uninitialized value, substr outside of string, non-numeric argument, ...) on stderr"
            echo "        produced_by: whichever ltl code path the warning text names (the warning carries the emitting line)"
            echo "        contract:    ltl must run warning-free on supported inputs; a runtime warning is an unguarded data path (tests/HARNESS-DESIGN.md section Runtime-warning cleanliness; issues #326, #341)"
        } >&2
        return 1
    fi

    return 0
}
