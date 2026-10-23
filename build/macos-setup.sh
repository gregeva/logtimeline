#!/bin/bash
#
# macOS development host setup: installs Homebrew Perl, Homebrew bash,
# Homebrew Python with NumPy and SciPy, cpanminus and the project's Perl
# modules, adds to the shell configuration only what a login shell is missing,
# and runs the environment check (process/check-environment.pl).
#
# Requirements:
#   - Homebrew (https://brew.sh). This script stops without it and never
#     installs it.
#
# Usage:
#   ./build/macos-setup.sh [--dev-deps] [--package]   full setup
#   ./build/macos-setup.sh --repair                   the shell configuration only
#   ./build/macos-setup.sh --validate                 the environment check only
#   ./build/macos-setup.sh -h | --help
#
# Runs under macOS's /bin/bash 3.2, since it runs before Homebrew bash exists.
# The shell configuration belongs to the developer: this script never
# rewrites, removes or duplicates a line in it. See
# docs/development-environment.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHECK="$REPO_ROOT/process/check-environment.pl"
BLOCK_BEGIN='# >>> ltl homebrew >>>'
BLOCK_END='# <<< ltl homebrew <<<'

usage() {
    cat <<'EOF'
Usage: build/macos-setup.sh [--dev-deps] [--package]
       build/macos-setup.sh --repair | --validate

Sets up a macOS host for working on ltl. Requires Homebrew.

  (no option)   full setup: install Homebrew Perl, bash, Python with NumPy
                and SciPy, cpanminus and the project's Perl modules; add to
                the shell configuration what a login shell is missing; run
                the environment check
  --dev-deps    full setup, plus the development-only modules (the profiler)
  --package     full setup, plus PAR::Packer, for building the static binary
  --repair      install nothing: add to the shell configuration only what
                the environment check finds missing, then run the check
  --validate    install and change nothing: run the environment check
  -h, --help    this text

--repair and --validate take no other option.
Exit status: the environment check's (0 nothing failed, 1 a condition
failed), 1 when Homebrew is not found, 2 on a usage error.
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

if ! command -v brew &>/dev/null; then
    echo "[error] Homebrew not found. Install from https://brew.sh"
    exit 1
fi

# Run a login zsh from a clean environment and print its value of each
# variable named. Only the variables a login shell needs to find its files are
# passed on, as the environment check does.
clean_login_shell() {
    local env_args=("HOME=$HOME") var
    for var in USER LOGNAME TERM ZDOTDIR; do
        if printenv "$var" >/dev/null; then
            env_args+=("$var=$(printenv "$var")")
        fi
    done
    env -i "${env_args[@]}" /bin/zsh -lc 'for v in "$@"; do printf "ltl:%s=%s\n" "$v" "${(P)v-}"; done' zsh "$@" </dev/null 2>/dev/null |
        sed -n 's/^ltl://p' || true
}

# The shell step of --repair and of the full setup. The environment check
# judges whether a login shell finds the tools (its condition 8), whoever
# wrote the lines that make it so. When it does not, and a login shell has not
# run Homebrew's own line (brew shellenv, which exports HOMEBREW_PREFIX), that
# line is the missing piece: it is added once, between markers, to the file
# every login zsh reads. Anything else lies in a line the developer owns.
shell_step() {
    echo "[shell] Does a login shell find the tools? (environment check, condition 8)"
    if perl "$CHECK" --condition 8; then
        echo "[shell] Nothing to add."
        return 0
    fi
    local zprofile prefix brew_prefix
    zprofile="${ZDOTDIR:-$HOME}/.zprofile"
    prefix="$(brew --prefix)"
    brew_prefix="$(clean_login_shell HOMEBREW_PREFIX | sed -n 's/^HOMEBREW_PREFIX=//p')"
    if [ -f "$zprofile" ] && grep -qxF "$BLOCK_BEGIN" "$zprofile"; then
        echo "[shell] Nothing added: $zprofile already holds this script's block, so the cause lies in another line; the report above shows what a login shell resolves."
    elif [ -n "$brew_prefix" ]; then
        echo "[shell] Nothing added: a login shell already runs Homebrew's line (HOMEBREW_PREFIX=$brew_prefix), so the cause lies in another line; the report above shows what a login shell resolves."
    else
        if [ -s "$zprofile" ]; then
            if [ -n "$(tail -c 1 "$zprofile")" ]; then
                printf '\n' >>"$zprofile"
            fi
            printf '\n' >>"$zprofile"
        fi
        printf '%s\n%s\n%s\n' "$BLOCK_BEGIN" "eval \"\$($prefix/bin/brew shellenv)\"" "$BLOCK_END" >>"$zprofile"
        echo "[shell] Added Homebrew's line to $zprofile: a login shell did not run it."
    fi
}

# Link each formula this script installs. brew install leaves a formula that is
# installed but not linked as it is; one whose files collide with files put
# there another way (a pip install, a copy by hand) cannot link. Those files
# are the developer's: they are named, grouped by directory, and left, and the
# setup stops. The collisions are found from the formula's own files before
# any link is made, without brew: a brew link that fails on one, and even
# brew link --dry-run, leaves directories behind in the prefix, and an empty
# package directory imports in Python as an empty namespace package.
# The Perl part prints "linked" for a linked formula, nothing for one that can
# link, and otherwise each colliding directory with its count of files.
link_formulae() {
    local formula state
    for formula in "$@"; do
        state="$(brew info --json=v2 "$formula" | perl -MJSON::PP -MFile::Find -MCwd=realpath -e '
            my ( $prefix, $cellar ) = @ARGV;
            my $f = decode_json( do { local $/; <STDIN> } )->{formulae}[0];
            if ( defined $f->{linked_keg} ) { print "linked\n"; exit 0 }
            my $keg = "$cellar/$f->{name}/$f->{installed}[-1]{version}";
            my %count;
            for my $top ( grep { -d "$keg/$_" } qw(bin sbin include lib share etc Frameworks) ) {
                find( { no_chdir => 1, wanted => sub {
                    return if -d $File::Find::name && !-l $File::Find::name;
                    ( my $rel = $File::Find::name ) =~ s{^\Q$keg\E/}{};
                    my $target = "$prefix/$rel";
                    return unless -e $target || -l $target;
                    my $real = realpath($target) // q{};
                    return if index( $real, realpath($keg) . q{/} ) == 0;
                    ( my $group = $target ) =~ s{(/site-packages/[^/]+)/.*}{$1} or $group =~ s{/[^/]+$}{};
                    $count{$group}++;
                } }, "$keg/$top" );
            }
            print "$count{$_} $_\n" for sort keys %count;
        ' "$(brew --prefix)" "$(brew --cellar)")"
        if [ "$state" = linked ]; then
            continue
        fi
        if [ -z "$state" ]; then
            echo "[link] Linking $formula"
            brew link "$formula"
            continue
        fi
        echo "[link] $formula is installed but cannot link: files already in place were not put there by Homebrew."
        echo "[link] They were installed another way, such as pip; setup leaves them. Files per directory:"
        printf '%s\n' "$state" | sed 's/^/         /'
        echo "[link] See docs/development-environment.md § Troubleshooting a failed condition, condition 7."
        exit 1
    done
}

if [ "$mode" = repair ]; then
    shell_step
    echo ""
    exec perl "$CHECK"
fi

echo "=========================================="
echo "macOS development host setup"
echo "=========================================="

echo "[1/7] Installing Homebrew Perl..."
brew install perl

# Homebrew Perl first on PATH for the rest of this run (not macOS system Perl)
BREW_PREFIX="$(brew --prefix)"
export PATH="${BREW_PREFIX}/opt/perl/bin:${PATH}"

# Persist PATH for subsequent GitHub Actions steps
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${BREW_PREFIX}/opt/perl/bin" >> "$GITHUB_PATH"
fi

echo "[info] Using Perl: $(which perl) ($(perl -v | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'))"

echo "[2/7] Installing Homebrew bash..."
# The test harnesses need bash 4 or later: macOS's /bin/bash 3.2 lets a harness
# that crashes on an unbound variable exit 0 (tests/lib/require-bash.sh).
brew install bash
export PATH="${BREW_PREFIX}/bin:${PATH}"
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${BREW_PREFIX}/bin" >> "$GITHUB_PATH"
fi

echo "[3/7] Installing Homebrew Python with NumPy and SciPy..."
# The statistics and distribution-shape harnesses check ltl against NumPy and
# SciPy; with Homebrew first on PATH, python3 is Homebrew's.
brew install python numpy scipy

echo "[4/7] Installing cpanminus..."
brew install cpanminus
link_formulae perl bash python numpy scipy cpanminus

if [ "$package" = 1 ]; then
    echo "[5/7] Installing PAR::Packer..."
    cpanm --notest PAR::Packer
else
    echo "[5/7] PAR::Packer not installed (--package installs it, for building the static binary)"
fi

echo "[6/7] Generating cpanfile and installing dependencies..."
cd "$SCRIPT_DIR"
./generate-cpanfile.sh
if [ "$dev_deps" = 1 ]; then
    echo "[info] Installing runtime and development-only dependencies (cpanm --notest --installdeps --with-develop .)"
    cpanm --notest --installdeps --with-develop .
else
    echo "[info] Installing runtime dependencies only (cpanm --notest --installdeps .)"
    echo "[info] --dev-deps also installs the development-only profiling tools."
    cpanm --notest --installdeps .
fi

echo "[7/7] Shell configuration..."
shell_step

echo ""
exec perl "$CHECK"
