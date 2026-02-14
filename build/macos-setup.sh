#!/bin/bash
#
# macOS Build Environment Setup Script
# Installs Homebrew Perl, cpanminus, PAR::Packer, and project dependencies
#
# Requirements:
#   - Homebrew (https://brew.sh)
#
# Usage:
#   ./build/macos-setup.sh
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

echo "[1/4] Installing Homebrew Perl..."
brew install perl

# Ensure Homebrew Perl is first on PATH (not macOS system Perl)
BREW_PREFIX="$(brew --prefix)"
export PATH="${BREW_PREFIX}/opt/perl/bin:${PATH}"

# Persist PATH for subsequent GitHub Actions steps
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${BREW_PREFIX}/opt/perl/bin" >> "$GITHUB_PATH"
fi

echo "[info] Using Perl: $(which perl) ($(perl -v | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'))"

echo "[2/4] Installing cpanminus..."
brew install cpanminus

echo "[3/4] Installing PAR::Packer..."
cpanm --notest PAR::Packer

echo "[4/4] Generating cpanfile and installing dependencies..."
cd "$SCRIPT_DIR"
if [ ! -f cpanfile ]; then
    ./generate-cpanfile.sh
fi
cpanm --notest --installdeps .

echo ""
echo "=========================================="
echo "macOS build environment ready"
echo "=========================================="
