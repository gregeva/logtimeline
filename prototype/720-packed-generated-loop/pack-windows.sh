#!/usr/bin/env bash
# #720: the container steps of build/windows-package.sh, packing the probe scripts, then testing them under Wine.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export WINEDEBUG=-all WINEPREFIX=/wine64
O=/x/out/windows-amd64; mkdir -p $O
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates curl unzip wine jq xz-utils file >/dev/null
wine --version
wine wineboot --init 2>/dev/null
GITHUB_URL=$(curl -fsSL --retry 3 --retry-delay 5 "https://api.github.com/repos/StrawberryPerl/Perl-Dist-Strawberry/releases/latest" \
  | jq -r '.assets[]?.browser_download_url | select(endswith("64bit-portable.zip"))' || true)
echo "Strawberry: $GITHUB_URL"
curl -fL --retry 4 --retry-delay 2 -o /tmp/strawberry.zip "$GITHUB_URL"
mkdir -p /opt/strawberry && unzip -q /tmp/strawberry.zip -d /opt/strawberry && rm -f /tmp/strawberry.zip
export STRAWBERRY=/opt/strawberry
export PATH="$STRAWBERRY/perl/bin:$STRAWBERRY/c/bin:$PATH"
wine reg add "HKEY_CURRENT_USER\\Environment" /v PATH /t REG_EXPAND_SZ /d "Z:\\opt\\strawberry\\perl\\bin;Z:\\opt\\strawberry\\c\\bin" /f 2>/dev/null || true
curl -fsSL --retry 3 --retry-delay 5 -o /tmp/cpanm.pl https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm
wine "$STRAWBERRY/perl/bin/perl.exe" /tmp/cpanm.pl --notest PAR::Packer Module::ScanDeps > $O/cpanm-par.log 2>&1
cd /x/build && wine "$STRAWBERRY/perl/bin/perl.exe" /tmp/cpanm.pl --notest --cpanfile cpanfile.windows --installdeps . > $O/cpanm-deps.log 2>&1; cd /x
for v in gen-run gen-file warn-gen-run warn-gen-file; do (cd /x/scripts/$v && wine "$STRAWBERRY/perl/bin/perl.exe" -S pp -o $O/$v.exe ltl); done
(cd /x/scripts/par0 && wine "$STRAWBERRY/perl/bin/perl.exe" -S pp -o $O/par0.exe par0.pl)
wine "$STRAWBERRY/perl/bin/perl.exe" -MPAR::Packer -e 'print "PAR::Packer $PAR::Packer::VERSION, perl $^V\n"'
file $O/*.exe
bash /x/test-pack.sh windows-amd64 .exe wine
