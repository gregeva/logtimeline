#!/usr/bin/env bash
# notices.sh — read the notice records of a capture's -V notices section
# (features/412-notice-surfaces.md § D15) by kind, for any harness that
# asserts a notice the tool raised. A notice is never read from standard
# error or from the rendered panel: its record is the observable surface.
#
# Public functions:
#   notice_section_present CAPTURE
#       Exit 0 when the capture holds the -V notices section.
#   notice_total CAPTURE
#       The section's count: every record the run raised. An absence check
#       ("the run says nothing about X") reads it, never an empty stderr.
#   notice_kind_count CAPTURE KIND
#       How many records of that kind the run raised (0 when none).
#   notice_field CAPTURE KIND FIELD
#       The field of each record of that kind, one record a line, in raising
#       order; a field with several lines (evidence) is joined by '|'.
#   notice_lines CAPTURE
#       One line per record, in raising order: kind, focus, statement,
#       evidence (its pieces joined by '; ') and remedy, separated by ' | ',
#       for a harness whose assertions match a whole notice by pattern.
#
# A capture without the section is a missing anchor: each function prints
# MISSING-SECTION, so a check against it fails.
#
# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "notices.sh is a library; source it, do not execute it" >&2
    exit 2
fi

notice_section_present() {
    grep -qx '=== notices ===' "$1" 2>/dev/null && grep -qx '=== END notices ===' "$1"
}

notice_total() {
    local capture="$1"
    if ! notice_section_present "$capture"; then echo MISSING-SECTION; return 0; fi
    awk '/^=== notices ===$/ { s = 1; next } /^=== END notices ===$/ { s = 0 } s && /^count: / { print substr($0, 8); exit }' "$capture"
}

notice_kind_count() {
    local capture="$1" kind="$2"
    if ! notice_section_present "$capture"; then echo MISSING-SECTION; return 0; fi
    awk -v k="$kind" '/^=== notices ===$/ { s = 1; next } /^=== END notices ===$/ { s = 0 }
        s && $0 == "  kind: " k { n++ } END { print n + 0 }' "$capture"
}

notice_field() {
    local capture="$1" kind="$2" field="$3"
    if ! notice_section_present "$capture"; then echo MISSING-SECTION; return 0; fi
    awk -v k="$kind" -v f="$field" '
        function flush() { if (cur == k) print val; cur = ""; val = ""; got = 0 }
        /^=== notices ===$/ { s = 1; next }
        /^=== END notices ===$/ { if (s) flush(); s = 0; next }
        !s { next }
        /^notice: / { flush(); next }
        /^  kind: / { cur = substr($0, 9) }
        index($0, "  " f ": ") == 1 { v = substr($0, length(f) + 5); val = got ? val "|" v : v; got = 1 }
    ' "$capture"
}

notice_lines() {
    local capture="$1"
    if ! notice_section_present "$capture"; then echo MISSING-SECTION; return 0; fi
    awk '
        function flush() { if (kind != "") print kind " | " focus " | " statement " | " evidence " | " remedy; kind = ""; evidence = "" }
        /^=== notices ===$/ { s = 1; next }
        /^=== END notices ===$/ { if (s) flush(); s = 0; next }
        !s { next }
        /^notice: / { flush(); next }
        /^  kind: /      { kind = substr($0, 9) }
        /^  focus: /     { focus = substr($0, 10) }
        /^  statement: / { statement = substr($0, 14) }
        /^  evidence: /  { v = substr($0, 13); evidence = evidence == "" ? v : evidence "; " v }
        /^  remedy: /    { remedy = substr($0, 11) }
    ' "$capture"
}
