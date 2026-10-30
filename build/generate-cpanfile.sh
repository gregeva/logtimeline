#!/usr/bin/env bash
#
# generate-cpanfile.sh : scan a Perl script for package dependencies, and build a CPAN file with those packages for easier project dependency management
#
# Usage:
#   ./build/generate-cpanfile.sh [script_name] [platform]
#
# Arguments:
#   script_name - Perl script to scan (default: ltl)
#   platform    - Target platform: macos, linux, windows, or all (default: this host's, from uname -s)
#
# Output (in build/ directory):
#   cpanfile.macos    - Dependencies for macOS (platform=macos or all)
#   cpanfile.linux    - Dependencies for Linux (platform=linux or all)
#   cpanfile.windows  - Dependencies for Windows (platform=windows or all)
#

# Determine the build directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SCRIPT_NAME=${1:-ltl}
TARGET_PLATFORM=${2:-}

usage() {
    echo "Usage: $0 [script_name] [macos|linux|windows|all]"
}

# With no platform named, this host's: the file its setup installs from.
if [[ -z "$TARGET_PLATFORM" ]]; then
    case "$(uname -s)" in
        Darwin) TARGET_PLATFORM=macos ;;
        Linux)  TARGET_PLATFORM=linux ;;
        MINGW* | MSYS* | CYGWIN*) TARGET_PLATFORM=windows ;;
        *)
            echo "Unknown host: $(uname -s); name the platform"
            usage
            exit 1
            ;;
    esac
fi

# Change to repo root for script scanning
cd "$REPO_ROOT"

# Platform-specific modules, each left out of the files of the platforms that
# never load it
UNIX_ONLY_MODULES=""
MACOS_ONLY_MODULES="BSD::Resource"
WINDOWS_ONLY_MODULES="Win32::API"

# Drop the lines naming any module in the given grep pattern; an empty pattern
# drops nothing (grep -v with an empty pattern would drop every line).
exclude_modules() {
    if [[ -n "$1" ]]; then grep -v "$1"; else cat; fi
}

generate_cpanfile() {
    local exclude_pattern="$1"
    perl -ne '
        BEGIN { binmode STDOUT }    # LF line endings under Windows Perl too
        if (/^\s*(?:use|require)\s+([A-Za-z0-9_:]+)(?:\s+([\d\._]+))?/) {
            my ($m,$ver) = ($1,$2);
            next if $m =~ /^(?:strict|warnings|feature|utf8|open|mro|base|parent|lib|constant|vars|attributes?|diagnostics|subs|integer)$/;
            next if $m eq "perl";
            print "requires \x27$m\x27", ($ver ? ", \x27>= $ver\x27" : ""), ";\n";
        }
    ' ${SCRIPT_NAME} | LC_ALL=C sort -u    # byte order, whatever the caller's locale
}

# Development-only dependencies, appended verbatim after the scanned runtime
# list so the generator stays the sole author of the file and two runs produce
# byte-identical output. ltl never loads these, so no scan can emit them.
# cpanm resolves this phase only when passed --with-develop, so every build and
# packaging path that calls the default form is unaffected.
append_develop_block() {
    local target="$1"
    {
        echo ""
        echo "on 'develop' => sub {"
        echo "    requires 'Devel::NYTProf';"
        echo "};"
    } | tee -a "$target"
}

# Write one platform's cpanfile: the scanned runtime list less the modules of
# the two given patterns, then the develop block.
write_cpanfile() {
    local target="$SCRIPT_DIR/cpanfile.$1"
    generate_cpanfile | exclude_modules "$2" | exclude_modules "$3" | tee "$target"
    append_develop_block "$target"
}

generate_macos_cpanfile() {
    write_cpanfile macos "$WINDOWS_ONLY_MODULES" ""
}

generate_linux_cpanfile() {
    write_cpanfile linux "$WINDOWS_ONLY_MODULES" "$MACOS_ONLY_MODULES"
}

generate_windows_cpanfile() {
    write_cpanfile windows "$UNIX_ONLY_MODULES" "$MACOS_ONLY_MODULES"
}

case "$TARGET_PLATFORM" in
    macos)
        echo "Generating build/cpanfile.macos for macOS..."
        generate_macos_cpanfile
        ;;
    linux)
        echo "Generating build/cpanfile.linux for Linux..."
        generate_linux_cpanfile
        ;;
    windows)
        echo "Generating build/cpanfile.windows for Windows..."
        generate_windows_cpanfile
        ;;
    all)
        echo "Generating build/cpanfile.macos (macOS)..."
        generate_macos_cpanfile
        echo ""
        echo "Generating build/cpanfile.linux (Linux)..."
        generate_linux_cpanfile
        echo ""
        echo "Generating build/cpanfile.windows (Windows)..."
        generate_windows_cpanfile
        ;;
    *)
        echo "Unknown platform: $TARGET_PLATFORM"
        usage
        exit 1
        ;;
esac
