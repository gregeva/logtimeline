#!/bin/bash
#
# macOS Build Environment Setup Script
# Installs Homebrew Perl, Homebrew bash, cpanminus, PAR::Packer, and project dependencies
#
# Requirements:
#   - Homebrew (https://brew.sh)
#
# Usage:
#   ./build/macos-setup.sh
#   LTL_INSTALL_DEV_DEPS=1 ./build/macos-setup.sh   # also install development-only tools
#
# Environment:
#   LTL_INSTALL_DEV_DEPS  Set to 1 to install the cpanfile's development-only
#                         phase (the profiler) alongside the runtime modules.
#                         Unset or 0 installs runtime modules only, which is
#                         what a release build wants.
#
# Note: macOS system Perl is known to be problematic — this script installs
#       Homebrew Perl to ensure a reliable build environment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "macOS Build Environment Setup"
echo "=========================================="

# Verify Homebrew is available
if ! command -v brew &>/dev/null; then
    echo "[error] Homebrew not found. Install from https://brew.sh"
    exit 1
fi

echo "[1/5] Installing Homebrew Perl..."
brew install perl

# Ensure Homebrew Perl is first on PATH (not macOS system Perl)
BREW_PREFIX="$(brew --prefix)"
export PATH="${BREW_PREFIX}/opt/perl/bin:${PATH}"

# Persist PATH for subsequent GitHub Actions steps
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${BREW_PREFIX}/opt/perl/bin" >> "$GITHUB_PATH"
fi

echo "[info] Using Perl: $(which perl) ($(perl -v | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'))"

echo "[2/5] Installing Homebrew bash..."
# The test harnesses need bash 4 or later: macOS's /bin/bash 3.2 lets a harness
# that crashes on an unbound variable exit 0 (tests/lib/require-bash.sh).
brew install bash
export PATH="${BREW_PREFIX}/bin:${PATH}"
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${BREW_PREFIX}/bin" >> "$GITHUB_PATH"
fi

echo "[3/5] Installing cpanminus..."
brew install cpanminus

echo "[4/5] Installing PAR::Packer..."
cpanm --notest PAR::Packer

echo "[5/5] Generating cpanfile and installing dependencies..."
cd "$SCRIPT_DIR"
./generate-cpanfile.sh
if [ "${LTL_INSTALL_DEV_DEPS:-0}" = "1" ]; then
    echo "[info] Installing runtime and development-only dependencies (cpanm --notest --installdeps --with-develop .)"
    cpanm --notest --installdeps --with-develop .
else
    echo "[info] Installing runtime dependencies only (cpanm --notest --installdeps .)"
    echo "[info] Set LTL_INSTALL_DEV_DEPS=1 to also install the development-only profiling tools."
    cpanm --notest --installdeps .
fi

echo ""
echo "=========================================="
echo "macOS build environment ready"
echo "=========================================="
