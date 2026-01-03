#!/bin/bash
#
# install-deps.sh : generate a CPAN package file (if not existing) and then install those package dependencies
#

if [ ! -f cpanfile ]; then
    ./generate-cpanfile.sh
fi

cpanm --notest --installdeps .
