#!/usr/bin/env bash
# #720: the container steps of build/ubuntu-package.sh, packing the probe scripts.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
O=/x/out/linux-$ARCH; mkdir -p $O
apt-get update -qq
apt-get install -y --no-install-recommends build-essential perl perl-base perl-modules libperl-dev cpanminus ca-certificates file >/dev/null
cpanm --notest PAR::Packer > $O/cpanm-par.log 2>&1
cd /x/build && cpanm --notest --installdeps . > $O/cpanm-deps.log 2>&1; cd /x
for v in gen-run gen-file warn-gen-run warn-gen-file; do (cd /x/scripts/$v && pp -o $O/$v ltl); done
(cd /x/scripts/par0 && pp -o $O/par0 par0.pl)
perl -MPAR::Packer -e 'print "PAR::Packer $PAR::Packer::VERSION, perl $^V\n"'
file $O/*
