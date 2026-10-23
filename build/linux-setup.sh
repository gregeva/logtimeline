#!/usr/bin/env bash
#
# Linux development host setup (Debian and Ubuntu): installs the
# distribution's Perl, bash, tmux, Python with NumPy and SciPy, and the
# distribution's package for each of the project's Perl modules, then runs the
# environment check (process/check-environment.pl).
#
# Everything comes from the distribution's packages, on its default PATH, so
# the shell configuration needs nothing added: no local::lib, no PERL5LIB.
#
# Requirements:
#   - apt-get, and sudo for the installs.
#
# Usage:
#   ./build/linux-setup.sh [--dev-deps] [--package]   full setup
#   ./build/linux-setup.sh --repair                   the shell configuration only
#   ./build/linux-setup.sh --validate                 the environment check only
#   ./build/linux-setup.sh -h | --help
#
# See docs/development-environment.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHECK="$REPO_ROOT/process/check-environment.pl"

# The distribution's package for each cpanfile module that is not part of
# Perl's own install. A module absent from this table must load from Perl's
# own install; the setup stops on one that does not.
declare -A PACKAGE_OF=(
    [Devel::NYTProf]=libdevel-nytprof-perl
    [Devel::Size]=libdevel-size-perl
    [PAR::Packer]=libpar-packer-perl
    [Term::ReadKey]=libterm-readkey-perl
    [Text::CSV]=libtext-csv-perl
    [Text::CSV_PP]=libtext-csv-perl
    [YAML::PP]=libyaml-pp-perl
    [YAML::PP::Common]=libyaml-pp-perl
    [YAML::PP::Schema::Core]=libyaml-pp-perl
    [YAML::PP::Schema::YAML1_1]=libyaml-pp-perl
)

usage() {
    cat <<'EOF'
Usage: build/linux-setup.sh [--dev-deps] [--package]
       build/linux-setup.sh --repair | --validate

Sets up a Debian or Ubuntu host for working on ltl, from the distribution's
packages. Installs with sudo apt-get.

  (no option)   full setup: install the distribution's Perl, bash, tmux,
                Python with NumPy and SciPy, and its package for each of the
                project's Perl modules; run the environment check
  --dev-deps    full setup, plus the development-only modules (the profiler)
  --package     full setup, plus PAR::Packer, for building the static binary
  --repair      install nothing: report whether a login shell finds the
                tools, then run the environment check
  --validate    install and change nothing: run the environment check
  -h, --help    this text

--repair and --validate take no other option.
Exit status: the environment check's (0 nothing failed, 1 a condition
failed), 1 when apt-get is not found or a module has no package, 2 on a
usage error.
EOF
}

mode=full
dev_deps=0
package=0
help=0
bad=0
for arg in "$@"; do
    case "$arg" in
        --dev-deps) dev_deps=1 ;;
        --package) package=1 ;;
        --repair | --validate)
            if [ "$mode" = full ]; then mode="${arg#--}"; else bad=1; fi
            ;;
        -h | --help) help=1 ;;
        *) bad=1 ;;
    esac
done
if [ "$mode" != full ] && [ $((dev_deps + package)) -gt 0 ]; then
    bad=1
fi
if [ "$bad" = 1 ]; then
    usage >&2
    exit 2
fi
if [ "$help" = 1 ]; then
    usage
    exit 0
fi

if [ "$mode" = validate ]; then
    exec perl "$CHECK"
fi

# The shell step of --repair and of the full setup. The distribution's tools
# are on its default PATH, so the setup has nothing to add to the shell
# configuration; when a login shell resolves other tools, a line the
# developer owns puts them first, and the check's report shows which.
shell_step() {
    echo "[shell] Does a login shell find the tools? (environment check, condition 8)"
    local report
    if report="$(perl "$CHECK" --condition 8)"; then
        echo "[shell] Yes. Nothing to add."
    else
        printf '%s\n' "$report"
        echo "[shell] Nothing added: the distribution's tools are on its default PATH, so a line in the shell configuration puts other tools first; the report above shows what a login shell resolves."
    fi
}

if [ "$mode" = repair ]; then
    shell_step
    echo ""
    exec perl "$CHECK"
fi

if ! command -v apt-get &>/dev/null; then
    echo "[error] apt-get not found. This setup is for Debian and Ubuntu hosts."
    exit 1
fi

echo "=========================================="
echo "Linux development host setup"
echo "=========================================="

echo "[1/4] Generating cpanfile..."
"$SCRIPT_DIR/generate-cpanfile.sh" >/dev/null

# The cpanfile's runtime modules, and with --dev-deps those of its develop block.
modules=$(perl -ne '
    BEGIN { ( $want, @ARGV ) = @ARGV }
    $develop = 1 if /^on\s+.develop./;
    $develop = 0 if /^\};/;
    print "$1\n" if /^\s*requires\s+.([\w:]+)./ && ( $develop ? $want : 1 );
' "$dev_deps" "$SCRIPT_DIR/cpanfile")
if [ "$package" = 1 ]; then
    modules="$modules"$'\n'"PAR::Packer"
fi

packages=(perl bash tmux python3 python3-numpy python3-scipy)
core=()
for module in $modules; do
    if [ -n "${PACKAGE_OF[$module]:-}" ]; then
        packages+=("${PACKAGE_OF[$module]}")
    else
        core+=("$module")
    fi
done
mapfile -t packages < <(printf '%s\n' "${packages[@]}" | sort -u)

echo "[2/4] Installing the distribution's packages..."
[ "$dev_deps" = 1 ] || echo "[info] --dev-deps also installs the development-only profiling tools."
[ "$package" = 1 ] || echo "[info] --package also installs PAR::Packer, for building the static binary."
echo "[info] sudo apt-get install ${packages[*]}"
sudo apt-get update -qq
sudo apt-get install -y -qq "${packages[@]}"

echo "[3/4] Modules from Perl's own install..."
missing=()
for module in "${core[@]}"; do
    perl -e "require $module" 2>/dev/null || missing+=("$module")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "[error] Not part of Perl's own install, and no package named for it in build/linux-setup.sh: ${missing[*]}"
    exit 1
fi
echo "[info] ${#core[@]} load: ${core[*]}"

echo "[4/4] Shell configuration..."
shell_step

echo ""
exec perl "$CHECK"
