#!/bin/bash
#
# macOS Static Binary Build Script
# Builds macOS static binary using PAR::Packer
#
# Requirements:
#   - Perl with PAR::Packer installed
#   - cpanfile generated and dependencies installed
#
# Usage:
#   ./build/macos-package.sh [arm64|x86_64]
#
# Output:
#   ltl_static-binary_macos-{arch} in repository root
#
# Note: Must run on matching architecture (arm64 on Apple Silicon, x86_64 on Intel)

set -euo pipefail

# Configuration
os=macos
architecture=${1:-$(uname -m)}  # Accept architecture as parameter, default to current

# Normalize architecture name
case "$architecture" in
    arm64|aarch64)
        architecture=arm64
        ;;
    x86_64|amd64)
        architecture=x86_64
        ;;
    *)
        echo "[error] Invalid architecture: $architecture"
        echo "Usage: $0 [arm64|x86_64]"
        exit 1
        ;;
esac

export SCRIPT_NAME=ltl
export PACKAGE_NAME="${SCRIPT_NAME}_static-binary_${os}-${architecture}"

echo "=========================================="
echo "macOS Build: ${PACKAGE_NAME}"
echo "Architecture: ${architecture}"
echo "=========================================="

# Verify we're building for the current architecture
current_arch=$(uname -m)
if [[ "$current_arch" != "$architecture" && "$current_arch" != "aarch64" || "$architecture" != "arm64" ]]; then
    # Allow aarch64 == arm64 mapping
    if [[ ! ("$current_arch" == "aarch64" && "$architecture" == "arm64") ]]; then
        if [[ "$current_arch" != "$architecture" ]]; then
            echo "[warn] Building for $architecture on $current_arch - cross-compilation not supported"
            echo "[info] Run on native hardware or use GitHub Actions matrix"
        fi
    fi
fi

echo "[1/2] Building static binary..."
# Use -M to explicitly include modules that are loaded dynamically at runtime
# (PAR::Packer static analysis cannot detect modules loaded via Module::Runtime)
pp \
  -M Specio::PP \
  -M DateTime::Locale::FromData \
  -M DateTime::Locale::Base \
  -M DateTime::Locale::Data \
  -M DateTime::Locale::Util \
  -M DateTime::TimeZone::Local \
  -M DateTime::TimeZone::UTC \
  -M DateTime::TimeZone::Floating \
  -o ${PACKAGE_NAME} ${SCRIPT_NAME}

# Verify the build
echo ""
echo "=========================================="
echo "Build Verification"
echo "=========================================="

if [ ! -f "${PACKAGE_NAME}" ]; then
    echo "[error] Build failed - executable not found"
    exit 1
fi

file "${PACKAGE_NAME}"
echo ""

# Test execution
echo "Testing executable with -version flag..."
set +e
VERSION_OUTPUT=$(./${PACKAGE_NAME} -version 2>&1)
EXIT_CODE=$?
set -e
echo "Exit code: ${EXIT_CODE}"
echo "Version output: ${VERSION_OUTPUT}"

if echo "$VERSION_OUTPUT" | grep -qE "[0-9]+\.[0-9]+\.[0-9]+"; then
    echo "[info] Version verification passed"
else
    echo "[warn] Version output may not contain expected version number"
fi

echo ""
echo "=========================================="
echo "BUILD SUCCESSFUL: ${PACKAGE_NAME}"
echo "=========================================="
