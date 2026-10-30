#!/usr/bin/env bash
#
# install-deps.sh : generate this host's CPAN package file (if not existing) and then install those package dependencies
#

case "$(uname -s)" in
    Darwin) CPANFILE=cpanfile.macos ;;
    Linux)  CPANFILE=cpanfile.linux ;;
    MINGW* | MSYS* | CYGWIN*) CPANFILE=cpanfile.windows ;;
    *) echo "Unknown host: $(uname -s)"; exit 1 ;;
esac

if [ ! -f "$CPANFILE" ]; then
    ./generate-cpanfile.sh
fi

cpanm --notest --cpanfile "$CPANFILE" --installdeps .
