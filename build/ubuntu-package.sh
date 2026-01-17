#!/bin/bash

# Choose the oldest Ubuntu that matches the glibc you need on targets
os=ubuntu
version=20.04  # or ubuntu:22.04 if that’s your target baseline
architecture=amd64
#architecture=arm64
export SCRIPT_NAME=ltl
export PACKAGE_NAME="${SCRIPT_NAME}_static-binary_${os}-${architecture}"

docker run --rm -it --platform=linux/$architecture \
   -e PACKAGE_NAME -e SCRIPT_NAME -v "$PWD":/work -w /work "${os}:${version}" bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    # Basic toolchain + Perl dev headers
    apt-get update
    apt-get install -y --no-install-recommends \
      build-essential perl perl-base perl-modules libperl-dev \
      cpanminus ca-certificates

    # Install PAR::Packer
    cpanm --notest PAR::Packer

    # Install your script/module deps:
    # OPTION 1: Use cpanfile (recommended)
    if [ -f cpanfile ]; then
      cpanm --notest --installdeps .
    fi

    # OPTION 2: Explicit modules if you don’t have cpanfile
    # cpanm --notest JSON LWP::UserAgent Foo::Bar

    # Build the executable with pp
    # Add --link/--addfile for non-glibc .so if needed
    pp -o ../${PACKAGE_NAME} ${SCRIPT_NAME}

    # Verify glibc baseline
    ldd --version
    ldd ${PACKAGE_NAME}
    '
