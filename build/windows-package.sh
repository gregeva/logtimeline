#!/bin/bash
#
# Windows Automated Build Script
# Builds Windows amd64 static binary using Rancher Desktop + Wine + Strawberry Perl
#
# Requirements:
#   - Rancher Desktop (https://rancherdesktop.io/)
#   - cpanfile generated (run ./build/generate-cpanfile.sh first)
#
# Usage:
#   ./build/windows-package.sh
#
# Output:
#   ltl_static-binary_windows-amd64.exe in repository root

set -euo pipefail

# Check container runtime is available (Rancher Desktop provides 'docker' command)
if ! command -v docker &>/dev/null; then
    echo "[error] Container runtime not found. Please install Rancher Desktop: https://rancherdesktop.io/"
    exit 1
fi

# Configuration
base_os=ubuntu
target_os=windows
version=20.04
architecture=amd64
# ARM64 Windows note: Strawberry Perl does not provide ARM64 builds.
# Windows ARM64 devices can run x64 executables via emulation.
# architecture=arm64  # Not supported - see features/windows-automated-build.md

export SCRIPT_NAME=ltl
export PACKAGE_NAME="${SCRIPT_NAME}_static-binary_${target_os}-${architecture}"

echo "=========================================="
echo "Windows Build: ${PACKAGE_NAME}.exe"
echo "Architecture: ${architecture}"
echo "=========================================="

# Check cpanfile exists
if [ ! -f "build/cpanfile" ]; then
    echo "[error] Missing build/cpanfile - run ./build/generate-cpanfile.sh first"
    exit 1
fi

docker run --rm --platform=linux/$architecture \
   -e PACKAGE_NAME -e SCRIPT_NAME -v "$PWD":/work -w /work/build "${base_os}:${version}" bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    export WINEDEBUG=-all WINEPREFIX=/wine64

    echo "[1/7] Installing system packages..."
    apt-get update -qq
    apt-get install -y --no-install-recommends \
      ca-certificates curl unzip wine jq xz-utils file >/dev/null

    echo "[2/7] Initializing Wine..."
    wine --version
    wine wineboot --init 2>/dev/null

    # Discover Strawberry Perl portable x64 ZIP
    echo "[3/7] Downloading Strawberry Perl..."
    GITHUB_API="https://api.github.com/repos/StrawberryPerl/Perl-Dist-Strawberry/releases/latest"
    GITHUB_URL=$(curl -fsSL "$GITHUB_API" \
      | jq -r ".assets[]?.browser_download_url | select(endswith(\"64bit-portable.zip\"))" || true)

    # Fallback to SourceForge mirror
    if [ -z "$GITHUB_URL" ]; then
      echo "[warn] GitHub asset not found, trying SourceForge mirror..."
      SF_INDEX="https://sourceforge.net/projects/perl-dist-strawberry.mirror/files/"
      SF_URL=$(curl -fsSL "$SF_INDEX" \
        | grep -Eo "https://sourceforge.net/projects/perl-dist-strawberry.mirror/files/[^\\\"]*64bit-portable\\.zip/download" \
        | head -n1 || true)
      if [ -n "$SF_URL" ]; then
        DOWNLOAD_URL="$SF_URL"
      else
        echo "[error] Could not resolve Strawberry Perl download URL"
        exit 1
      fi
    else
      DOWNLOAD_URL="$GITHUB_URL"
    fi

    echo "[info] Download URL: $DOWNLOAD_URL"
    curl -fL --retry 4 --retry-delay 2 -o /tmp/strawberry.zip "$DOWNLOAD_URL"

    # Validate ZIP
    if ! unzip -t /tmp/strawberry.zip >/dev/null 2>&1; then
      echo "[error] ZIP integrity check failed"
      exit 1
    fi

    echo "[4/7] Extracting Strawberry Perl..."
    mkdir -p /opt/strawberry
    unzip -q /tmp/strawberry.zip -d /opt/strawberry
    rm -f /tmp/strawberry.zip

    export STRAWBERRY=/opt/strawberry
    export PATH="$STRAWBERRY/perl/bin:$STRAWBERRY/c/bin:$PATH"

    echo "[5/7] Installing PAR::Packer..."
    curl -fsSL -o /tmp/cpanm.pl https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm
    wine "$STRAWBERRY/perl/bin/perl.exe" /tmp/cpanm.pl --notest PAR::Packer Module::ScanDeps 2>&1 | tail -5

    echo "[6/7] Installing dependencies from cpanfile..."
    wine "$STRAWBERRY/perl/bin/perl.exe" /tmp/cpanm.pl --notest --installdeps . 2>&1 | tail -10

    echo "[7/7] Building Windows executable..."
    wine "$STRAWBERRY/perl/bin/perl.exe" -S pp -o ../${PACKAGE_NAME}.exe ../${SCRIPT_NAME}

    # Verify the build
    echo ""
    echo "=========================================="
    echo "Build Verification"
    echo "=========================================="

    # Check file exists and type
    if [ ! -f "../${PACKAGE_NAME}.exe" ]; then
      echo "[error] Build failed - executable not found"
      exit 1
    fi

    file "../${PACKAGE_NAME}.exe"

    # Verify executable runs and outputs version
    echo ""
    echo "Testing executable with -version flag..."
    VERSION_OUTPUT=$(wine "../${PACKAGE_NAME}.exe" -version 2>/dev/null || true)
    echo "Version output: ${VERSION_OUTPUT}"

    if [ -z "$VERSION_OUTPUT" ]; then
      echo "[error] Build verification failed - executable did not produce version output"
      exit 1
    fi

    echo ""
    echo "=========================================="
    echo "BUILD SUCCESSFUL: ${PACKAGE_NAME}.exe"
    echo "=========================================="
    '
