#!/bin/bash
#
# profiling-preflight.sh — verify the environment can run a profiling session
#
# Usage:
#   ./build/profiling-preflight.sh
#
# Checks, in order:
#   1. The interpreter on PATH is not macOS system Perl.
#   2. The profiler module loads for that interpreter.
#   3. The HTML report tool resolves to an executable path.
#
# When check 2 or 3 fails the development-only dependencies are installed and
# the two checks are repeated, unless LTL_PROFILING_INSTALL is 0.
#
# Environment:
#   LTL_PROFILING_INSTALL  1 (default) attempts the install on a miss;
#                          0 checks only and fails on a miss.
#   LTL_PROFILING_SCRIPT_DIR  Overrides the directory searched for the HTML
#                          report tool, for exercising the missing-tool path.
#
# Exit codes:
#   0  the interpreter is acceptable, the profiler loads, the HTML tool resolves
#   1  macOS system Perl is on PATH
#   2  the profiler or the HTML tool is missing and could not be installed
#   3  cpanm is not available
#
# Resolution carries no literal interpreter or module path: the interpreter is
# whatever `perl` on PATH resolves to, and its script directory is read from
# that interpreter's own configuration, so both follow a Perl upgrade.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROFILER_MODULE="Devel::NYTProf::Data"
HTML_TOOL="nytprofhtml"
INSTALL_COMMAND="cd build && cpanm --notest --installdeps --with-develop ."
SETUP_COMMAND="./build/macos-setup.sh"

RESOLVED_PERL=""
RESOLVED_HTML_TOOL=""

# --- Check 1: the interpreter is not macOS system Perl -----------------------
check_interpreter() {
    if ! command -v perl >/dev/null 2>&1; then
        echo "[error] No perl found on PATH." >&2
        echo "  $SETUP_COMMAND" >&2
        return 1
    fi
    RESOLVED_PERL="$(command -v perl)"
    case "$RESOLVED_PERL" in
        /usr/bin/*|/System/*)
            echo "[error] PATH resolves perl to macOS system Perl ($RESOLVED_PERL), which this repository does not support." >&2
            echo "  $SETUP_COMMAND" >&2
            return 1
            ;;
    esac
    return 0
}

# --- Check 2: the profiler module loads --------------------------------------
# The data API is the one tests/profile/extract-profile.pl loads, so checking it
# checks what a profiling run actually uses.
check_profiler_module() {
    perl "-M${PROFILER_MODULE}" -e 1 >/dev/null 2>&1
}

# --- Check 3: the HTML report tool resolves ----------------------------------
# cpanm installs scripts into the running Perl's own script directory, which
# Homebrew does not link onto PATH. Asking the interpreter where it installs
# scripts answers for the interpreter that will run, whatever version it is.
# `perl -S` is the fallback for a setup where scripts do land on PATH.
check_html_tool() {
    local script_dir
    if [ -n "${LTL_PROFILING_SCRIPT_DIR:-}" ]; then
        script_dir="$LTL_PROFILING_SCRIPT_DIR"
    else
        script_dir="$(perl -e 'use Config; print $Config{installsitescript}' 2>/dev/null)"
    fi

    if [ -n "$script_dir" ] && [ -x "$script_dir/$HTML_TOOL" ]; then
        RESOLVED_HTML_TOOL="$script_dir/$HTML_TOOL"
        return 0
    fi

    local via_path
    via_path="$(perl -e 'use File::Spec; my $t = shift;
        for my $d (File::Spec->path) { my $p = File::Spec->catfile($d, $t); if (-x $p) { print $p; last } }' \
        "$HTML_TOOL" 2>/dev/null)"
    if [ -n "$via_path" ] && [ -x "$via_path" ]; then
        RESOLVED_HTML_TOOL="$via_path"
        return 0
    fi

    return 1
}

# --- The install the preflight runs ------------------------------------------
# One declaration, one install path: the cpanfile's development-only phase is
# the single place a development dependency is named.
install_dev_dependencies() {
    if ! command -v cpanm >/dev/null 2>&1; then
        echo "[error] cpanm is not available, so the profiling tools cannot be installed." >&2
        echo "  $SETUP_COMMAND" >&2
        return 3
    fi
    echo "[info] The profiling tools are missing for $RESOLVED_PERL. Installing the development-only dependencies."
    if ( cd "$SCRIPT_DIR" && cpanm --notest --installdeps --with-develop . ); then
        return 0
    fi
    echo "[error] The install of the development-only dependencies failed." >&2
    echo "  $INSTALL_COMMAND" >&2
    return 2
}

report_missing() {
    local what="$1"
    echo "[error] $what is missing for $RESOLVED_PERL." >&2
    echo "  $INSTALL_COMMAND" >&2
}

# --- Main --------------------------------------------------------------------
check_interpreter || exit 1

need_install=0
check_profiler_module || need_install=1
check_html_tool || need_install=1

if [ "$need_install" -eq 1 ]; then
    if [ "${LTL_PROFILING_INSTALL:-1}" != "1" ]; then
        check_profiler_module || report_missing "The profiler module $PROFILER_MODULE"
        check_html_tool || report_missing "The HTML report tool $HTML_TOOL"
        echo "[error] The install was not attempted." >&2
        exit 2
    fi

    install_dev_dependencies
    install_status=$?
    if [ "$install_status" -ne 0 ]; then
        exit "$install_status"
    fi

    if ! check_profiler_module; then
        report_missing "The profiler module $PROFILER_MODULE"
        echo "[error] It is still missing after the install." >&2
        exit 2
    fi
    if ! check_html_tool; then
        report_missing "The HTML report tool $HTML_TOOL"
        echo "[error] It is still missing after the install." >&2
        exit 2
    fi
fi

PROFILER_VERSION="$(perl -MDevel::NYTProf::Core -e 'print $Devel::NYTProf::Core::VERSION // q{unknown}' 2>/dev/null)"
[ -n "$PROFILER_VERSION" ] || PROFILER_VERSION="unknown"

echo "[ok] Interpreter:   $RESOLVED_PERL"
echo "[ok] Profiler:      Devel::NYTProf $PROFILER_VERSION"
echo "[ok] HTML report:   $RESOLVED_HTML_TOOL"
exit 0
