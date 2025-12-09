#!/bin/bash

# Choose the oldest Ubuntu that matches the glibc you need on targets
base_os=ubuntu
target_os=windows
version=20.04  # or ubuntu:22.04 if that’s your target baseline
architecture=amd64
export SCRIPT_NAME=ltl
export PACKAGE_NAME="${SCRIPT_NAME}_static-binary_${target_os}-${architecture}"

echo "Selected system architecture: ${architecture}"

docker run --rm -it --platform=linux/$architecture \
   -e PACKAGE_NAME -e SCRIPT_NAME -v "$PWD":/work -w /work "${base_os}:${version}" bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    export WINEDEBUG=-all WINEPREFIX=/wine64
    set -x

    # Basic toolchain + Perl dev headers
    apt-get update
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl unzip wine jq xz-utils
#      build-essential perl perl-base perl-modules libperl-dev cpanminus \

    which wine || which wine
    wine --version

    wine wineboot --init			# Initialize Wine

    # Get Strawberry Perl Portable x64


    # 1) Discover latest Strawberry Perl portable x64 ZIP from GitHub Releases
    #    We pick the asset whose name ends with "-64bit-portable.zip"
    echo "[info] Querying GitHub Releases for latest portable x64 asset..."
    GITHUB_API="https://api.github.com/repos/StrawberryPerl/Perl-Dist-Strawberry/releases/latest"
    GITHUB_URL=$(curl -fsSL "$GITHUB_API" \
      | jq -r ".assets[]?.browser_download_url | select(endswith(\"64bit-portable.zip\"))" || true)

    # 2) Fallback: SourceForge mirror for the latest tagged release
    #    We try to infer the tag from releases page and construct a mirror URL.
    if [ -z "$GITHUB_URL" ]; then
      echo "[warn] GitHub latest asset not resolved, trying SourceForge mirror..."
      # Mirror listing of latest (we parse the first portable zip found)
      SF_INDEX="https://sourceforge.net/projects/perl-dist-strawberry.mirror/files/"
      # Find a path that contains "-64bit-portable.zip"
      SF_URL=$(curl -fsSL "$SF_INDEX" \
        | grep -Eo "https://sourceforge.net/projects/perl-dist-strawberry.mirror/files/[^\\\"]*64bit-portable\\.zip/download" \
        | head -n1 || true)
      if [ -n "$SF_URL" ]; then
        # SourceForge uses /download links; curl -L will resolve to the actual file
        DOWNLOAD_URL="$SF_URL"
      else
        echo "[error] Could not resolve a portable x64 ZIP from SourceForge mirror."
        exit 1
      fi
    else
      DOWNLOAD_URL="$GITHUB_URL"
    fi

    echo "[info] Download URL: $DOWNLOAD_URL"

    # 3) Download and validate ZIP
    rm -f /tmp/strawberry.zip
    curl -fL --retry 4 --retry-delay 2 -o /tmp/strawberry.zip "$DOWNLOAD_URL"


    # Validate ZIP integrity
    if ! unzip -t /tmp/strawberry.zip >/dev/null 2>&1; then
      echo "[error] ZIP integrity check failed."
      head -n 10 /tmp/strawberry.zip || true
      exit 1
    fi

    # Extract and install Strawberry Perl
    mkdir -p /opt/strawberry
    unzip -q /tmp/strawberry.zip -d /opt/strawberry

    export STRAWBERRY=/opt/strawberry
    export PATH="$STRAWBERRY/perl/bin:$STRAWBERRY/c/bin:$PATH"


    # Check Make tools and versions for building dependencies


    wine /opt/strawberry/perl/bin/perl.exe -V:make
    wine /opt/strawberry/c/bin/gmake.exe --version || echo "gmake.exe missing"
    wine /opt/strawberry/c/bin/dmake.exe -V      || echo "dmake.exe missing"
    wine /opt/strawberry/c/bin/gcc.exe --version
    wine /opt/strawberry/c/bin/g++.exe --version

    which gmake
    wine where gmake

    # Install PAR::Packer + deps (Windows side, via Wine)
    # curl -L -o /tmp/cpanm.pl https://cpanmin.us
    curl -fsSL -o /tmp/cpanm.pl https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm

    wine "$STRAWBERRY/perl/bin/perl.exe" /tmp/cpanm.pl --notest PAR::Packer Module::ScanDeps
#    cpanm --notest PAR::Packer			 # Install PAR::Packer

    if [ -f cpanfile ]; then			 # Install your script/module deps
      wine "$STRAWBERRY/perl/bin/perl.exe" /tmp/cpanm.pl --notest --installdeps .
      find /opt/strawberry/data -type f -name build.log -exec sh -c \'echo "=== {} ==="; tail -n 20 "{}"\' \;

#      cpanm --notest --installdeps .
    else
      printf "ERROR: Missing cpanfile (needs to be generated before build process as a dependency)"
      exit 1
    fi

    # Build the executable with pp
#    pp -o ${PACKAGE_NAME} ${SCRIPT_NAME}

    # Verify glibc baseline
#    ldd --version
#    ldd ${PACKAGE_NAME}


    # Build Windows exe
    wine "$STRAWBERRY/perl/bin/perl.exe" -S pp -o ${PACKAGE_NAME}.exe ${SCRIPT_NAME}

    # Show result type
    file ${PACKAGE_NAME}.exe
    sleep infinity


    '
