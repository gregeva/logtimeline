#!/bin/bash
#
# Ubuntu/Linux Static Binary Build Script
# Builds Linux static binary using Docker
#
# Requirements:
#   - Docker (or Rancher Desktop)
#   - cpanfile generated (run ./build/generate-cpanfile.sh first)
#
# Usage:
#   ./build/ubuntu-package.sh [amd64|arm64]
#
# Output:
#   ltl_static-binary_ubuntu-{arch} in repository root

set -euo pipefail

# Configuration
os=ubuntu
version=20.04  # Oldest Ubuntu for broad glibc compatibility
architecture=${1:-amd64}  # Accept architecture as parameter, default to amd64

# Validate architecture
if [[ "$architecture" != "amd64" && "$architecture" != "arm64" ]]; then
    echo "[error] Invalid architecture: $architecture"
    echo "Usage: $0 [amd64|arm64]"
    exit 1
fi

export SCRIPT_NAME=ltl
export PACKAGE_NAME="${SCRIPT_NAME}_static-binary_${os}-${architecture}"

echo "=========================================="
echo "Ubuntu Build: ${PACKAGE_NAME}"
echo "Architecture: ${architecture}"
echo "=========================================="

# Check cpanfile exists
if [ ! -f "build/cpanfile" ]; then
    echo "[error] Missing build/cpanfile - run ./build/generate-cpanfile.sh first"
    exit 1
fi

docker run --rm --platform=linux/$architecture \
   -e PACKAGE_NAME -e SCRIPT_NAME -v "$PWD":/work -w /work "${os}:${version}" bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    echo "[1/4] Installing system packages..."
    apt-get update -qq
    apt-get install -y --no-install-recommends \
      build-essential perl perl-base perl-modules libperl-dev \
      cpanminus ca-certificates file >/dev/null

    echo "[2/4] Installing PAR::Packer..."
    cpanm --notest PAR::Packer

    echo "[3/4] Installing dependencies from cpanfile..."
    if [ -f build/cpanfile ]; then
      cd build && cpanm --notest --installdeps .
      cd ..
    fi

    echo "[4/4] Building static binary..."
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
    ldd --version | head -1
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
    '
