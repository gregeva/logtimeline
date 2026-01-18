#!/bin/bash
#
# generate-cpanfile.sh : scan a Perl script for package dependencies, and build a CPAN file with those packages for easier project dependency management
#
# Usage:
#   ./build/generate-cpanfile.sh [script_name] [platform]
#
# Arguments:
#   script_name - Perl script to scan (default: ltl)
#   platform    - Target platform: unix, windows, or all (default: all)
#
# Output (in build/ directory):
#   cpanfile          - Dependencies for Unix platforms (or all if platform=all)
#   cpanfile.windows  - Dependencies for Windows (only when platform=windows or all)
#

# Determine the build directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SCRIPT_NAME=${1:-ltl}
TARGET_PLATFORM=${2:-all}

# Change to repo root for script scanning
cd "$REPO_ROOT"

# Platform-specific modules that should be excluded from cross-platform builds
UNIX_ONLY_MODULES="Proc::ProcessTable"
WINDOWS_ONLY_MODULES="Win32::Process::Info"

generate_cpanfile() {
    local exclude_pattern="$1"
    perl -ne '
        if (/^\s*(?:use|require)\s+([A-Za-z0-9_:]+)(?:\s+([\d\._]+))?/) {
            my ($m,$ver) = ($1,$2);
            next if $m =~ /^(?:strict|warnings|feature|utf8|open|mro|base|parent|lib|constant|vars|attributes?|diagnostics|subs)$/;
            next if $m eq "perl";
            print "requires \x27$m\x27", ($ver ? ", \x27>= $ver\x27" : ""), ";\n";
        }
    ' ${SCRIPT_NAME} | sort -u
}

case "$TARGET_PLATFORM" in
    unix)
        echo "Generating build/cpanfile for Unix..."
        generate_cpanfile | grep -v "$WINDOWS_ONLY_MODULES" | tee "$SCRIPT_DIR/cpanfile"
        ;;
    windows)
        echo "Generating build/cpanfile.windows for Windows..."
        generate_cpanfile | grep -v "$UNIX_ONLY_MODULES" | tee "$SCRIPT_DIR/cpanfile.windows"
        ;;
    all)
        echo "Generating build/cpanfile (Unix)..."
        generate_cpanfile | grep -v "$WINDOWS_ONLY_MODULES" | tee "$SCRIPT_DIR/cpanfile"
        echo ""
        echo "Generating build/cpanfile.windows (Windows)..."
        generate_cpanfile | grep -v "$UNIX_ONLY_MODULES" | tee "$SCRIPT_DIR/cpanfile.windows"
        ;;
    *)
        echo "Unknown platform: $TARGET_PLATFORM"
        echo "Usage: $0 [script_name] [unix|windows|all]"
        exit 1
        ;;
esac
