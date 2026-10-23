# 750: scripts find bash and Perl from the environment the setup prepared

Issue: #750 (scripts set their own PATH from `brew --prefix`, which works around
the environment setup and fails where Homebrew is absent). Parent: #729
(process, tests and build).

Status: specification reworked on the issue branch `750-interpreter-resolution`
(2026-10-23) for the architect's direction that the check judges the
environment and setup never overwrites the user's shell configuration (D12,
D6 as changed, D13, condition 8 retired); stage 1 (the macOS development
host) planned in § Stage 1 implementation plan; steps 0 (the `before`
benchmark) and 1 (`process/check-environment.pl`) done, next step 2 (the
session-start hook). Open, measured in stage 1: what still needs the
Perl keg line on `PATH` (§ Phase 4: what Homebrew's own configuration already
provides on macOS). What is in
place today is recorded as found, not as the contract: most of it was put in
piecemeal to get past a problem at the time, and the analysis is expected to
challenge it.

## The architect's framing (2026-10-23)

- **The requirement is the expected Perl, consistently.** Every consumer (the
  developer's shell, the agent, the harnesses, the hooks, profiling,
  benchmarks, builds) runs the one Perl that carries the modules the
  application and the development environment install. Homebrew Perl is how
  macOS meets that, not the requirement: 544 D1 and the profiling setup
  pinned Homebrew Perl because the agent was at times picking up the macOS
  system Perl. Profiling is to work on Windows and Linux as well.
- **Which interpreter comes first is an environment setup problem.** The order
  `PATH` is built in belongs to each host's setup script, not to the scripts
  that run afterwards. The `export PATH="$(brew --prefix)..."` line and the
  absolute Homebrew paths are workarounds of a setup that did not do this.
- **`tests/lib/require-bash.sh` is a workaround of the same kind:** macOS's
  `/bin/bash` 3.2 let a crashed harness exit 0.
- **Windows has two runtime environments, and both must hold:** the CI build,
  Strawberry Perl under Wine in a Linux container (no Windows kernel), and a
  real Windows host (Windows kernel and file structure).
- **Linux has no development setup.** It has no Homebrew, while the primary
  development environment relies on Homebrew; a Linux development setup
  script is likely needed.
- **Python is held to the same requirement.** The harnesses use Python
  (NumPy, SciPy); every consumer runs the Python the development setup
  installs, never whatever the system happens to carry.
- **Some limits are strict and stay:** screenshot capture runs on macOS and
  Linux only, because of the dependencies it uses; the terminal-interface
  navigation tests need tmux and run on macOS and Linux only.
- **The analysis runs on each operating system.** Cross-system investigation
  stages try, test and, where needed, build the setup on the host it is for
  (macOS, Linux, a real Windows host, the Wine build), rather than reasoning
  about a host from another one.
- The way forward is the cleanest, most coherent one the analysis finds, and
  it may change earlier decisions; nothing is locked up front.
- **The check judges the environment; setup does not overwrite it**
  (2026-10-23, at the start of stage 1). The point of the work is to check
  that the environment is set up properly, whatever configured it. Homebrew is
  not used by ltl alone: many developers use it all the time and already carry
  its configuration in their shell files, so setup does not overwrite that
  configuration or add a redundant copy of it. Adding a piece is legitimate
  when `--repair` runs and the check has found that piece missing, or when
  setup itself installed Homebrew. The architect then settled that Homebrew
  is a requirement of the macOS host: setup stops when it is absent and never
  installs it (D13), so only the first case arises.

## What it is for

A developer on any of the three development hosts (macOS, Linux, Windows) runs
`ltl`, the harnesses, the prototypes' scripts and the setup scripts without
editing anything and without reading a message about a tool their platform
does not have. Each host's setup prepares the environment once; every script
then takes bash and Perl from that environment, the same way on every host.

## The class of fault

One class, several forms: **the interpreter is named by where Homebrew put it,
instead of being taken from the environment the setup prepared.** The two
prototype scripts the issue reports are one form of it. Found by
`git grep brew` and `git grep opt/homebrew` over `release/0.20.0` at `ca586d3f`.

| Form | Occurrences | What a reader observes where Homebrew is absent or elsewhere |
|---|---|---|
| `PATH` set from `brew --prefix` | `prototype/412-notice-surfaces/check-tmux.sh`, `prototype/412-notice-surfaces/capture/specimens.sh` | `brew: command not found` twice on Linux, then the run continues on the shell's own `PATH` (`prototype/412-notice-surfaces/findings.md` § Claude's runs on Linux, before the architect's round) |
| Interpreter named by an absolute Homebrew path | `ltl` line 1, `#!/opt/homebrew/bin/perl`; `PERL="${PERL:-/opt/homebrew/bin/perl}"` in 15 harnesses, 14 of which fall back to `perl` when the path is missing and one (`tests/validate-section-layout.sh`) does not; `prototype/426-asbuilt-run.sh`; the example command in `tests/profile/checks/README.md` | `/opt/homebrew` is Homebrew's prefix on Apple silicon only; on an Intel Mac it is `/usr/local`, and Linux has none. Not yet run on Linux: what `./ltl` does there |
| A workaround of the shebang | `build/windows-setup.ps1` writes a one-line wrapper at Git's `/opt/homebrew/bin/perl` that runs Strawberry Perl | exists only so that `ltl`'s first line resolves on Windows |
| A hint naming Homebrew to every platform | `tests/lib/require-bash.sh`: "Install Homebrew bash (build/macos-setup.sh) and put `$(brew --prefix)/bin` first on PATH." | a Linux developer with bash older than 4 is told to install Homebrew |
| Setup and instructions | `build/macos-setup.sh` exports `PATH` for its own process and, under CI, appends to `GITHUB_PATH`; it writes nothing to the developer's shell profile. `CLAUDE.md` § Test and benchmark and `README.md` § Test-harness dependencies tell the developer to export the `brew --prefix` line themselves | macOS gets Homebrew first on `PATH` by a manual step; Windows gets Strawberry Perl first by a managed block the setup writes into `~/.bashrc` |

## What is in place today

| Surface | As built | Record line behind it |
|---|---|---|
| The development interpreter on macOS | Homebrew Perl, never the system Perl | `features/544-upgrade-safe-profiling-setup.md` D1 (locked): "The development environment stays Homebrew Perl." |
| How a script finds Perl | `perl` from `PATH` | 544 D7 (delegated): "The interpreter is `perl` from PATH. On a documented setup this is already Homebrew Perl, because `build/macos-setup.sh` puts `$(brew --prefix)/opt/perl/bin` ahead of the system directories." |
| How a script finds bash | bash 4 or later, first on `PATH`; older bash stops the script | `tests/lib/require-bash.sh` header: "Homebrew bash is installed by build/macos-setup.sh and must come first on PATH, as Homebrew Perl does." |
| The harnesses on macOS | the shell they start from finds Homebrew bash and Perl first | `README.md` § Test-harness dependencies: "the shell you run the harnesses from must then find them first on its PATH" |
| The harnesses on Windows | do not run there | `docs/toolchain-guidance.md` § Windows development host: "The test harnesses do not run on Windows."; #751 (harnesses on Windows through WSL or Cygwin) is labelled `not planned` |
| `./ltl` on Windows | runs from Git Bash through the shim | `docs/toolchain-guidance.md` § Windows development host, trap 3: "`./ltl` names `/opt/homebrew/bin/perl`. Git Bash resolves `/opt` under the Git install, so the script writes a one-line wrapper ..." |
| Perl on Windows | Strawberry Perl first on `PATH` through `~/.bashrc` | `docs/toolchain-guidance.md` § Windows development host, trap 4 |
| Linux | system Perl and cpanm from the distribution; nothing said about `PATH` | `README.md` § Install Dependencies, Ubuntu/Linux block |

Observation, not yet a finding: 544 D7 states that `build/macos-setup.sh` puts
Homebrew Perl ahead of the system directories. The script does so for its own
run and for later CI steps; a developer's next shell is not changed by it.

## Analysis

Phases: (1) where an interpreter starts, and from what context; (2) the
problem each workaround got past; (3) how the agent came to run the system
Perl; (4) what each host's setup establishes, and the one rule every script
follows; (5) requirements, decisions and acceptance criteria per host.

### Phase 1: where an interpreter starts, and from what context (macOS part)

Every launch point, by the context it runs in and how that context gets its
`PATH`. "Measured" rows were run on the macOS development host on 2026-10-23;
the others are read from the scripts and wait for a run on their host.

| Context | How `PATH` arrives | Perl | bash | Python | Source |
|---|---|---|---|---|---|
| Developer's interactive zsh, macOS | `~/.zshrc`: `brew shellenv`, then the Perl keg prepended | Homebrew | Homebrew 5 | Homebrew | measured |
| A non-interactive zsh started from a clean environment, macOS, login or not | `/etc/paths` through `path_helper`: `/usr/bin` and `/bin` come before `/opt/homebrew/bin`, which `/etc/paths.d/homebrew` appends | `/usr/bin/perl` | `/bin/bash` 3.2 | `/usr/bin/python3` | measured |
| The agent's Bash tool | runs the user's login shell (`$SHELL`, here `/bin/zsh -c`), not bash, despite its name; each command first sources a snapshot Claude Code writes at session start (`~/.claude/shell-snapshots/snapshot-zsh-*.sh`), whose last line exports the `PATH` of the shell that started Claude Code (here an interactive login `-zsh`). No rc file is read per command, so the `PATH` is fixed for the session | Homebrew | Homebrew 5 | Homebrew | measured, this session |
| A script the agent runs, by its `env bash` shebang or as `bash script` | a non-interactive bash, which reads no rc file and inherits the `PATH` above | from `PATH` | Homebrew 5 | from `PATH` | read |
| Claude Code hooks | Claude Code's environment; `perl` named explicitly for the two Perl hooks, `session-start.sh` by its `env bash` shebang | from `PATH` | from `PATH` | n/a | read |
| git pre-commit hook | git's environment, `#!/usr/bin/env bash` | n/a | from `PATH` | n/a | read |
| A harness starting `ltl` | `"$LTL"`, so `ltl`'s first line: `/opt/homebrew/bin/perl`, whatever `PATH` holds | fixed path | n/a | n/a | read |
| A harness starting a Perl helper | `perl` from `PATH`, or `$PERL`, defaulting to `/opt/homebrew/bin/perl` in 15 harnesses | mixed | n/a | n/a | read |
| A harness starting Python | `python3` from `PATH`, in every harness that uses it | n/a | n/a | from `PATH` | read |
| CI, macOS runner | `build/macos-setup.sh` exports `PATH` and appends to `GITHUB_PATH` | Homebrew | Homebrew 5 | Homebrew | read |
| CI, Ubuntu runner | `build/generate-cpanfile.sh` on the runner's own Perl; the build inside an `ubuntu:20.04` container on its apt Perl | system, by design | system | n/a | read |
| CI, Windows build | Strawberry Perl under Wine in a Linux container; `perl.exe` named by its path inside the container the script builds | Strawberry, fixed path | container's | n/a | read |
| Real Windows host, Git Bash | `~/.bashrc` managed block puts Strawberry Perl first; `./ltl` resolves through the shim at Git's `/opt/homebrew/bin/perl` | Strawberry | Git Bash | WinGet Python | read |
| Linux development host | nothing the repository sets; the distribution's own | `/usr/bin/perl` | distribution's | distribution's | read; `./ltl`'s first line not yet run there |

What the measured rows show: on the macOS development host, the environment
that finds Homebrew Perl, bash and Python is set up only in `~/.zshrc`, which
only an interactive zsh reads. Any shell that does not descend from one, login
shells included, resolves `/usr/bin/perl`, `/bin/bash` 3.2 and
`/usr/bin/python3`. A tool started that way (an application launched from the
Dock, an editor's task runner, a scheduled job, a hook run by a graphical git
client) runs the system interpreters. This is a candidate mechanism for the
agent's past use of the system Perl, examined in phase 3.

### Phase 3: how the wrong interpreter has been reached (set aside)

The architect starts Claude Code from a terminal, never from the desktop app,
so the agent's shell inherits the interactive environment and its `PATH`
(measured in this session: Homebrew Perl, bash and Python). The
non-interactive shell above therefore does not explain the agent's past use
of the system Perl in a terminal-started session, unless `~/.zshrc` did not
yet carry the Homebrew lines at the time; its comment matches the wording
`README.md` gained when the harnesses started refusing bash 3.2 (2026-09-24).

Set aside by the architect (2026-10-23): the incidents span a year and a
half, and the work is a redesign, not a per-incident fix. What was found
before that is kept below.

Cases on record, found by searching issues and commit messages for
"system Perl":

| Mechanism | Case | What was observed |
|---|---|---|
| A tool script found on `PATH` carries the shebang of another Perl | #85 (the macOS build missed `Devel::Size`) | bare `pp` ran under the system Perl's PAR::Packer, which could not see the modules installed for the active Perl; fixed by `perl -S pp` |
| An interpreter named by an absolute path that stops being right | #544 (profiling setup) | the pinned keg path no longer existed after a Homebrew Perl upgrade |
| A script whose first line names the system Perl | `#!/usr/bin/perl` in five prototype scripts (`prototype/426-revalidate-v6.pl`, `-v7.pl`, `-v8-rebless.pl`, `prototype/heatmap-mini.pl`, `prototype/heatmap-test.pl`) | run by their path, they start `/usr/bin/perl` whatever `PATH` holds; no recorded failure |
| A shell context that does not read `~/.zshrc` | phase 1, measured | system Perl, bash 3.2 and system Python |

### Direction (architect, 2026-10-23)

Not yet locked; the shape the design is being worked toward.

- **One environment check, read-only, in one script**, holding one list of
  expectations shared by every host. Where hosts differ (Homebrew Perl on
  macOS, Strawberry Perl on Windows), an expectation carries a per-host
  alternative inside the same list, not a separate list per host.
- **The check runs before setup has run**, on all three operating systems, so
  it cannot count on bash, PowerShell or the right Perl. It is written in
  Perl: a developer of a Perl application has some Perl, even the wrong one,
  on every host.
- **Each setup script has a `--validate` mode** that installs and changes
  nothing and runs the check; a full setup ends by running it.
- **A session-start check** runs it when a Claude Code session starts, so a
  wrong environment is reported before work begins. CI runs outside Claude
  Code and has no session start; it is out of scope for this check.
- **The session-start hook's shape (agreed):** a shell-form hook, so each
  platform starts it with the shell Claude Code guarantees there (`sh` on
  macOS and Linux, Git Bash on Windows). Its command is a few lines of `sh`:
  when a `perl` is on `PATH`, run the check script with it; when none is,
  print that no Perl was found and name the setup for the host. The check
  itself is the one Perl script, run by whatever Perl is present and
  reporting which one it found. Claude Code does not bundle Node (its
  `claude` is a native executable that "does not itself invoke Node",
  https://code.claude.com/docs/en/setup.md), so Node is not a runtime the
  hook can count on. A Windows host without Git Bash, where Claude Code
  falls back to PowerShell, is treated as not set up.
- **Linux's expected Perl (agreed as the starting point, not a hard
  requirement):** the distribution's Perl, with the project's modules
  installed under the developer's home through `local::lib` (`~/perl5`,
  `PERL5LIB` in the shell configuration): no root, and the same Perl the CI
  Linux build uses. The Linux investigation stage tries it on a Linux host
  and settles what Linux ends up with; where it does not work out, it is
  changed, not forced.
- **Setup makes the shell configuration right without reinstalling
  anything:** the step that writes it is idempotent, or setup has a fix mode
  that repairs the configuration alone.
- What the check tests is the requirement, not a location: the `perl` on
  `PATH` loads the project's modules, `bash` on `PATH` is 4 or later,
  `python3` on `PATH` imports NumPy and SciPy, and the host-limited tools
  (tmux, the screenshot tools) are present where they are expected.

### Phase 4: the expected conditions (agreed by the architect, 2026-10-23)

One list; a cell names the per-host alternative where hosts differ. "Fail"
stops the session-start report at a problem to fix; "note" reports without
failing. Each condition is tested by running the tool found on `PATH`, never
by trusting the Perl the check runs under.

| # | Condition | macOS | Linux | Windows (Git Bash) | Severity |
|---|---|---|---|---|---|
| 1 | a `perl` is on `PATH` | | | | fail |
| 2 | it is the development Perl, not another on the host | Homebrew's, not `/usr/bin` or `/System` | the distribution's | Strawberry Perl's, not Git's own `/usr/bin/perl` | fail |
| 3 | it loads every runtime module the cpanfile requires | `build/cpanfile` | `build/cpanfile` | `build/cpanfile.windows` | fail |
| 4 | it loads the development-only modules (the profiler) | when installed (`--dev-deps`) | when installed (`--dev-deps`) | when installed (`--dev-deps`), once `build/cpanfile.windows` carries the develop block (544 D5a as amended) | note |
| 5 | modules installed under the home are visible to it | n/a | `PERL5LIB` carries `~/perl5` | n/a | fail |
| 6 | `bash` on `PATH` is 4 or later | Homebrew's | the distribution's | Git Bash | fail |
| 7 | `python3` on `PATH` imports NumPy and SciPy | Homebrew's, not `/usr/bin/python3` | the distribution's | the WinGet Python | fail where the harnesses run, note on Windows |
| 8 | a login shell started from a clean environment resolves the same `perl`, `bash` and `python3` as conditions 2, 6 and 7; the report also shows, for context, what a new terminal tab (an interactive login shell) and a plain non-login shell resolve | `zsh -lc`; `~/.zprofile` (D6) | a login bash | a Git Bash login shell | fail |
| 9 | `tmux` is on `PATH` | expected | expected | not expected | note |
| 10 | the screenshot tools are present | `swiftc` (Xcode command line tools) | established in the Linux stage | not expected | note |
| 11 | the repository checks files out with LF endings | n/a | n/a | `core.autocrlf=false` | fail |

**Profiling on Windows (architect, 2026-10-23):** profiling works on Windows
too; 544 D5a is amended so that `build/cpanfile.windows` carries the develop
block. Finding, read from the code: `build/windows-setup.ps1 -DevDeps` adds
`--with-develop` to `cpanm --cpanfile cpanfile.windows --installdeps .`, and
`generate_windows_cpanfile()` in `build/generate-cpanfile.sh` writes that
file without the develop block, so the switch installs nothing beyond the
runtime modules, while `docs/toolchain-guidance.md` § Windows development
host states "`-DevDeps` adds the profiler" and the script's own help says
"Also install the development-only Perl modules (the profiler)". Not yet run
on a Windows host.

Condition 8 is the measured fault of phase 1: the Homebrew interpreters were
set up only in `~/.zshrc`, read by interactive shells alone.

### Phase 4: where macOS setup writes its shell configuration (measured)

The same block (`brew shellenv`, then the Perl keg prepended) placed in a
throwaway `ZDOTDIR` and each zsh mode started from a clean environment on the
macOS development host, 2026-10-23:

| Block in | `zsh -c` | `zsh -lc` (login) | `zsh -ic` (interactive) | `zsh -lic` (terminal tab) |
|---|---|---|---|---|
| `.zshenv` only | Homebrew | `/usr/bin/perl` | Homebrew | `/usr/bin/perl` |
| `.zprofile` only | `/usr/bin/perl` | Homebrew | `/usr/bin/perl` | Homebrew |
| both | Homebrew | Homebrew | Homebrew | Homebrew |

`.zshenv` alone loses every login shell, because `/etc/zprofile` runs
`path_helper` after it and puts `/usr/bin` back in front; `.zprofile` alone
misses every shell that is not a login shell. Only the block in both files
resolves Homebrew's tools in every mode.

**Decided by the architect (2026-10-23): the tools must resolve in every login
shell, as Homebrew advises; on macOS the place is `~/.zprofile` alone.**
Homebrew's installer puts its line in `~/.zprofile`, so a developer who
followed it already passes and nothing of ltl's is added. Login shells cover
every new terminal tab and what descends from it (Claude Code, its Bash tool,
its hooks, the harnesses), `ssh host command`, and a script's `zsh -l`. Not
covered, and not required: an application's plain `zsh -c`, which reads only
`~/.zshenv`. A copy in `~/.zshenv` was set aside because it adds to the
user's configuration beyond what Homebrew asks for, runs `brew shellenv` in
every zsh (about 20 ms measured, including each agent command), and still
misses the `sh` and `bash` children of applications, such as git hooks run
by a graphical client, which read no zsh file at all.

This host, each mode started from a clean environment (2026-10-23), with the
developer's Homebrew lines in `~/.zshrc` and no `~/.zprofile`:

| Mode | `perl` | `bash` | `python3` |
|---|---|---|---|
| `-c` | `/usr/bin/perl` | `/bin/bash` | `/usr/bin/python3` |
| `-lc` | `/usr/bin/perl` | `/bin/bash` | `/usr/bin/python3` |
| `-ic` | `/opt/homebrew/opt/perl/bin/perl` | `/opt/homebrew/bin/bash` | `/opt/homebrew/bin/python3` |
| `-lic` | `/opt/homebrew/opt/perl/bin/perl` | `/opt/homebrew/bin/bash` | `/opt/homebrew/bin/python3` |

Every terminal tab is right, and every non-interactive login shell runs the
system tools; under this decision the clean login shell condition fails here
until Homebrew's line is in `~/.zprofile`.

### Phase 4: what Homebrew's own configuration already provides on macOS (measured)

A login zsh started from a clean environment (`env -i HOME="$HOME" /bin/zsh
-lc`) on the macOS development host, 2026-10-23, read-only: first with the
developer's files as they are (no `~/.zprofile`; the Homebrew lines only in
`~/.zshrc`), then with Homebrew's own line, `eval "$(/opt/homebrew/bin/brew
shellenv)"`, run first in the same shell.

| Tool | Files as they are | Homebrew's line alone |
|---|---|---|
| `perl` | `/usr/bin/perl` | `/opt/homebrew/bin/perl`, a link into the Cellar (5.44.0); `Text::CSV`, `YAML::PP`, `Term::ReadKey` and `Devel::Size` load |
| `bash` | `/bin/bash` (3.2) | `/opt/homebrew/bin/bash` (5.3) |
| `python3` | `/usr/bin/python3` | `/opt/homebrew/bin/python3`; NumPy and SciPy import |
| `nytprofhtml` | not found | not found |
| `pp` | `/usr/bin/pp`, the system Perl's script (`#!/usr/bin/perl`) | `/usr/bin/pp` |

Homebrew's own line meets the Perl, bash and Python conditions. The Perl keg
line that `~/.zshrc` adds (`$(brew --prefix)/opt/perl/bin` first) is ltl's only
addition beyond it. The keg's `bin` holds the scripts cpanm installs for
Homebrew Perl (`nytprofhtml` and the other profiler tools, `scandeps.pl`, the
`yamlpp-*` tools), which Homebrew does not link. The profiling preflight finds
`nytprofhtml` through the interpreter's own `installsitescript` (544 D7) and
needs no `PATH` entry for it. `build/macos-package.sh` starts `perl -S pp`,
which searches `PATH`; without the keg line it finds the system Perl's
`/usr/bin/pp`. Whether that still packages correctly is not measured:
PAR::Packer is not installed for Homebrew Perl 5.44 on this host, and measuring
it means installing it.

The condition this host fails today is the clean login shell (condition 8):
the developer's Homebrew lines are in `~/.zshrc`, which only an interactive
shell reads.

### Phase 4: re-running setup is not safe for the shell configuration

`brew install --help`: "Unless $HOMEBREW_NO_INSTALL_UPGRADE is set, brew
install formula will upgrade formula if it is already installed but
outdated." Re-running `build/macos-setup.sh` to repair the shell
configuration can therefore upgrade Perl across a minor version, which leaves
its CPAN modules behind (544 § Machine state and mechanism). The architect's
condition is that setup never reinstalls anything to put the configuration
right.

**Decided by the architect (2026-10-23): each setup script has three modes.**

| Mode | Installs | Writes the shell configuration | Runs the check |
|---|---|---|---|
| full setup (no switch) | yes | as `--repair` | yes, last |
| `--repair` | no | only the pieces the check found missing, each added once | yes, before writing and after |
| `--validate` | no | no | yes |

`--repair` cannot install or upgrade anything by construction; it is what puts
the shell configuration right once the cause of a failed condition is found
to lie there. It never rewrites or duplicates a line the user already has
(§ The architect's framing): it adds a piece only when the check reports that
piece missing, delimited so that a later run recognises its own addition and
adds nothing. Making the
full setup safe to re-run was the alternative, set aside because every install
step on every host (Homebrew's upgrade-on-install, WinGet, cpanm) would have
to become a guaranteed no-op, each a separate promise to keep and test.

### Phase 4: one option set for every setup script (decided by the architect, 2026-10-23)

The setup options today are three conventions: `build/macos-setup.sh` takes no
arguments and reads `LTL_INSTALL_DEV_DEPS=1` (544 D6); `build/windows-setup.ps1`
takes PowerShell switches `-DevDeps` and `-Package`, plus `-Phase Machine`, the
elevated re-launch of itself; the modes decided above are written `--repair`
and `--validate`. The repository's other scripts take double-dash, lower-case,
hyphenated long options with `-h`/`--help` (`--scenario`, `--list` in every
harness through `tests/lib/scenario-select.sh`; `--label`, `--force`,
`--no-html` in `tests/profile/run-profile.sh`; `--label`, `--options` in
`tests/baseline/run-benchmark.sh`), and an unknown option exits non-zero
having done nothing.

The same options, spelled the same way, on all three setup scripts. The
architect named the development option `--dev-deps`; it passes cpanm
`--with-develop`.

| Option | Effect | Replaces |
|---|---|---|
| (none) | full setup: install the runtime tools and modules, write the shell configuration, run the check | |
| `--dev-deps` | full setup, plus the development-only modules (the profiler) | `LTL_INSTALL_DEV_DEPS=1` on macOS, `-DevDeps` on Windows |
| `--package` | full setup, plus PAR::Packer, for building the static binary | `-Package` on Windows; on macOS PAR::Packer is installed unconditionally today |
| `--repair` | run the check, add to the shell configuration only the pieces it found missing, then run the check again | |
| `--validate` | run the check only | |
| `-h`, `--help` | usage | |

- `--repair` and `--validate` take neither install option; given together, or
  with an unknown option, the script exits non-zero having done nothing.
- `.github/workflows/release-build.yml` runs `./build/macos-setup.sh` bare, then
  packages; under this set it runs `./build/macos-setup.sh --package`. A bare
  run still installs no profiler, which keeps the property 544 D6 chose the
  environment variable for; D6's other reason, that the script had no option
  parser, goes with the modes.
- `-Phase Machine` stays internal to `build/windows-setup.ps1` (the script
  re-launching itself elevated) and is not part of the set.
- Not yet known: whether `powershell -File build\windows-setup.ps1 --validate`
  reaches the script as `--validate` through PowerShell's own parameter
  binding, or has to be read from `$args`. Stage 3 settles it.

### Phase 4: the one rule every script follows

With the environment established by setup and asserted by the check, a script
takes `perl`, `bash` and `python3` from `PATH` and nothing else:

- First lines are `#!/usr/bin/env perl`, `#!/usr/bin/env bash`,
  `#!/usr/bin/env python3`; a script starts another interpreter by its bare
  name. No absolute interpreter path, no `brew --prefix`, no change to `PATH`.
- A harness's `PERL` override stays as an override and defaults to `perl`.
- **Exceptions, each a sealed environment that builds its own `PATH`:** the
  setup scripts (they establish it), and the two container builds
  (`build/ubuntu-package.sh` inside `ubuntu:20.04`, `build/windows-package.sh`
  naming Strawberry Perl inside its Wine container).
- `tests/lib/require-bash.sh` stays: it guards a harness started from any
  shell, inside a session or not. Its message names the host's setup and its
  `--validate`, not Homebrew.

What the rule removes or rewrites, against the inventory in § The class of
fault:

| Occurrence | Becomes |
|---|---|
| `ltl` line 1 `#!/opt/homebrew/bin/perl` | `#!/usr/bin/env perl` |
| the Windows shim at Git's `/opt/homebrew/bin/perl` | no longer written; full setup removes one left by an earlier run |
| `PERL="${PERL:-/opt/homebrew/bin/perl}"` in 15 harnesses | `PERL="${PERL:-perl}"`, and the per-harness fallback line goes |
| `PATH` set from `brew --prefix` in the two notice-surface prototype scripts | removed |
| `#!/usr/bin/perl` in seven prototype scripts (the five of phase 3, plus `prototype/colors` and `prototype/colors-256`), `/opt/homebrew/bin/perl` in `prototype/426-asbuilt-run.sh` | `env perl`, bare `perl` |
| the example in `tests/profile/checks/README.md` | bare `perl` |
| the `export PATH="$(brew --prefix)..."` lines in `CLAUDE.md` and `README.md` | the host's setup, and its `--validate` |
| `require-bash.sh`'s Homebrew hint | names the host's setup and `--validate` |
| historical records (`tests/profile/results/*`, `releases/*`, past investigations, `build/packaging-notes`, the prototype reports that name the Perl they ran under) | untouched: they record the interpreter of their time |
| `prototype/720-packed-generated-loop/pack-windows.sh`, which sets `PATH` to Strawberry Perl inside its Wine container | untouched: the container steps of `build/windows-package.sh`, a sealed environment |
| `tests/validate-screenshot-capture.sh`, which runs the capture tool with `PATH` cut down to a directory without the tools | untouched: the test's own fixture for an absent tool |

Stage 1 audit (2026-10-23): the AC13 search over the issue branch at
`54b29fe2` printed 52 lines; beyond the inventory above it found
`#!/usr/bin/perl` in `prototype/colors` and `prototype/colors-256`, added to the
prototype row, and the three untouched rows just above.

### Phase 4: investigation stages, one per environment

Each stage runs on the host it is for, tries the setup and the check there, and
records what it finds here before the next.

| Stage | Host | What it establishes |
|---|---|---|
| 1 | macOS development host | the check script, the session-start hook, `build/macos-setup.sh` with `--repair` and `--validate`, the rule applied to every script; the harness suite passes |
| 2 | Linux development host | a new Linux setup script (the distribution's Perl, `local::lib`), the check's Linux column, the screenshot tools on Linux; the harness suite passes |
| 3 | Windows development host | `build/windows-setup.ps1` with `--repair` and `--validate`, the check under Git Bash, `./ltl` through `env perl` with no shim, the hooks, the profiler with `--dev-deps`, the option set parsed by PowerShell |
| 4 | the container builds | `build/windows-package.sh` (Wine) and `build/ubuntu-package.sh` build as before, with the develop block in `build/cpanfile.windows` |

### How Claude Code runs a hook (documentation, read 2026-10-23)

From https://code.claude.com/docs/en/hooks.md and
https://code.claude.com/docs/en/hooks-guide.md:

- **Shell form** (no `args`): "The `command` string is passed to a shell:
  `sh -c` on macOS and Linux, Git Bash on Windows, or PowerShell when Git Bash
  isn't installed." A per-hook `shell` field chooses `bash` or `powershell`.
- **Exec form** (`args` present): "Claude Code resolves `command` as an
  executable on `PATH` and spawns it directly with `args` as the argument
  vector. There is no shell". On Windows it needs a real executable (a
  `.exe`), and the documentation names "the `node` plus script-path pattern"
  as the one that "works on every platform because `node.exe` is a real
  binary". `perl` with a script path is the same pattern.
- **Environment:** "A hook process inherits the parent environment", the
  environment of the Claude Code process, not the Bash tool's snapshot.
- **Languages:** the examples are shell with `jq`, PowerShell for Windows, and
  Node for exec form; there is no section on writing hooks for several
  platforms.
- **SessionStart:** plain stdout, or `additionalContext`, goes into the
  model's context; `systemMessage` is shown to the user; exit 2 shows stderr
  as a hook error notice and the session proceeds. Default timeout 600 s; the
  documentation asks for these hooks to be fast.
- **Paths:** exec form is preferred for any hook that names
  `$CLAUDE_PROJECT_DIR`; in shell form the placeholder is double-quoted.

## Records found

`./process/find-records.sh --issues 'brew --prefix' 'opt/homebrew' 'require-bash' 'shebang' 'Homebrew bash' 'Homebrew Perl' 'macos-setup' 'windows-setup'`

| Record | Disposition |
|---|---|
| `features/544-upgrade-safe-profiling-setup.md` | read: D1 and D7 govern this work |
| `docs/toolchain-guidance.md` | read: § Windows development host, traps 3 and 4, and the harnesses' Windows exclusion |
| `README.md` § Install Dependencies, § Test-harness dependencies | read: the setup instructions per host |
| `tests/lib/require-bash.sh` | read: the bash 4 requirement and its hint |
| `prototype/412-notice-surfaces/findings.md` | read: § Claude's runs on Linux, where the fault was found |
| #751 (harnesses on Windows) | read: not planned; bounds what "validated on Windows" can cover |
| `features/nytprof-profiling-workflow.md`, `tests/profile/profiling-preflight.sh` | read: already resolve through `perl` from `PATH` (544 D7) |
| `features/227-binary-smoke-coverage.md`, `features/503-yaml-aggregate-export.md`, `features/189-histogram-bin-counter-primitives.md`, `features/342-redundant-logic-surfaces-audit-report.md`, `features/213-consolidation-regression-investigation.md`, `features/memory-tracking-improvements.md`, `releases/v0.12.2.md`, `tests/profile/results/*` | dismissed: records of past runs and past releases, which name the interpreter of their time |
| `tests/distribution-shape/generate-anchor.py`, the Python hints in `tests/validate-statistics.sh`, `tests/validate-profile.sh`, `tests/validate-distribution-shape.sh` | dismissed: each hint is labelled with the platform it is for |
| #106, #138, #328, #434, #541 | dismissed: closed, matched a term in passing |


## Requirements

Written in the specification stage; the architect closed the stage without a line-by-line review (2026-10-23).

- **R1. One environment check.** A single Perl script tests the eleven
  conditions of § Phase 4: the expected conditions, and reports each one by
  number with its result (pass, fail, note), what it expected on this host,
  what it found (the path and version of the tool on `PATH`, the module that
  did not load), the context it ran in (the Perl it ran under, the `PATH` it
  saw), and, for every condition not passing, a pointer to that condition's
  entry in § Troubleshooting a failed condition of this document. It does not
  carry remedies: whoever reads the report, the developer or the agent, reads
  the entry and investigates the host it is on. It is read-only: it installs,
  writes and changes nothing.
- **R2. The check runs before setup.** It uses core Perl modules only, so any
  Perl runs it: the macOS system Perl, Git for Windows' own Perl, a
  distribution's Perl. It tests the tools it finds on `PATH` by starting them,
  never the Perl it runs under.
- **R3. A session-start check.** A shell-form SessionStart hook runs a few
  lines of `sh`: with a `perl` on `PATH` it runs the check, without one it
  reports that no Perl was found, with the `PATH` it saw and the pointer to
  condition 1's troubleshooting entry. The report goes into the model's
  context; a failed condition and its pointer are also shown to the user.
  The session always proceeds. It is its own hook entry, beside the
  outstanding-state sweep of `process/claude-hooks/session-start.sh`.
- **R4. Three setup modes on every host.** `build/macos-setup.sh`,
  `build/windows-setup.ps1` and a new Linux setup script each have a full
  setup, `--repair` and `--validate` (§ Phase 4: re-running setup is not safe
  for the shell configuration). `--repair` and `--validate` install and
  upgrade nothing. The full setup ends by running the check. All three take
  the one option set of § Phase 4: one option set for every setup script.
- **R5. Setup adds only what is missing from the shell configuration.** The
  check judges whether the shell configuration resolves the expected tools,
  whoever wrote its lines. Setup never rewrites, removes or duplicates a line
  the user already has. It adds a piece only when the check reports that piece
  missing (`--repair`, and the full setup's shell step, which is the same).
  Homebrew is a requirement of the macOS host, not something setup installs
  (D13). Each addition is delimited,
  so that a later run recognises it and adds nothing. On macOS, Homebrew's
  own line already meets the Perl, bash and Python conditions (§ Phase 4: what
  Homebrew's own configuration already provides on macOS); the Perl keg line
  is ltl's only addition beyond it, and is added only for what is measured to
  need it.
- **R6. One rule for every script** (§ Phase 4: the one rule every script
  follows): interpreters from `PATH`, by `env` first lines and bare names; no
  absolute interpreter path, no `brew --prefix`, no change to `PATH`, outside
  the sealed environments named there. Every occurrence in the rewrite table
  is changed as it states.
- **R7. Python under the same rule.** `python3` is the one setup installs;
  condition 7 asserts it.
- **R8. Profiling on every host.** `build/cpanfile.windows` carries the
  develop block (544 D5a as amended); `--dev-deps` installs the profiler on
  every host; no packaged binary carries it.
- **R9. No message about a tool the host does not have.** No script prints a
  message from, or a remedy naming, a tool absent from the host it runs on.
- **R10. The records say what is now true.** `README.md` § Install
  Dependencies and § Test-harness dependencies, `CLAUDE.md` § Build and §
  Test and benchmark, and `docs/toolchain-guidance.md` § Windows development
  host name the host's setup and its modes in place of the manual `export
  PATH` line and the shim; 544 D1 and D7 are restated against the
  requirement the architect gave (the expected Perl, consistently, which on
  macOS is Homebrew Perl).

## Decisions

| | Decision | By |
|---|---|---|
| D1 | One read-only check, in Perl, one list of conditions with per-host alternatives; the conditions as listed, twelve when decided, eleven once the one about setup's block was retired under D12 | architect |
| D2 | The session-start hook: shell form, an `sh` launcher, the Perl check | architect |
| D3 | Linux starts from the distribution's Perl with `local::lib`; not a hard requirement, settled in the Linux stage | architect |
| D4 | Setup modes: full, `--repair`, `--validate` | architect |
| D9 | One option set on every setup script: `--dev-deps`, `--package`, `--repair`, `--validate`, `-h`/`--help`; CI's macOS step runs `--package`; 544 D6's environment variable goes | architect |
| D5 | Profiling on every host; 544 D5a amended | architect |
| D6 | The development tools must resolve in every login shell, as Homebrew advises; on macOS the place is `~/.zprofile` alone, and a plain non-login `zsh -c` is not required to resolve them (first taken, delegated, as both `~/.zshenv` and `~/.zprofile`; changed under D12) | architect |
| D7 | The one rule and its exceptions; `require-bash.sh` stays as a guard with a host-neutral message | delegated |
| D8 | The environment check is its own SessionStart hook entry | delegated |
| D10 | No harness for this work. The acceptance criteria are test cases written out in this document; the developer runs each one by hand on the hosts it names, at that host's stage, and records the result under it | architect |
| D11 | The check reports what it expected, what it found and the context it ran in, and points at the failed condition's entry in this document's § Troubleshooting a failed condition; it carries no remedies, and the agent or developer reading it works out the cause on the host from that entry | architect |
| D12 | The check judges the environment, whatever configured it; setup never overwrites or duplicates the user's shell configuration, and adds a piece only when `--repair` (or the full setup's shell step) finds it missing | architect |
| D13 | Homebrew is a requirement of the macOS development host: `build/macos-setup.sh` stops when it is absent, as today, and never installs it. The case in D12's first wording, setup adding Homebrew's line after installing Homebrew itself, therefore does not arise | architect |

## Acceptance criteria

Written in the specification stage (2026-10-23). Each criterion is a test case the
developer runs by hand, on the hosts it names (M macOS, L Linux, W Windows
under Git Bash, C the container builds), at that host's stage; no harness is
built for them (D10). Under each, the developer records the host, the date
and what the run showed. The check is `process/check-environment.pl`, and
`<setup>` is the host's setup script (`build/macos-setup.sh`, the Linux setup
stage 2 creates, `build/windows-setup.ps1`).

A **throwaway home** is made with `T=$(mktemp -d)` and used as
`HOME="$T" ZDOTDIR="$T"`, so the developer's own files are never touched. A
**stand-in directory** is `D=$(mktemp -d)` holding symbolic links or small
scripts, put first on `PATH` to change what one name resolves to.

**The check (R1, R2)**

- [ ] **AC1. A set-up host passes.** Run `<setup> --validate`.
      Pass when: all eleven conditions are reported by number, each one
      applicable to the host passes or is a note, those not applicable are
      reported as such, and the exit status is 0. M L W.
- [ ] **AC2. The wrong Perl first on `PATH` is reported, and the check still
      runs under it.** macOS: `PATH="/usr/bin:/bin:$PATH" /usr/bin/perl
      process/check-environment.pl`. Windows: `PATH="/usr/bin:$PATH"
      /usr/bin/perl process/check-environment.pl` (Git's own Perl).
      Pass when: the check completes under that Perl; condition 2 fails,
      naming the Perl found and the one expected; the report gives the Perl it
      ran under and the `PATH` it saw; and condition 2 carries the pointer to
      its troubleshooting entry. The exit status is non-zero. M W.
      - M, 2026-10-23, pass: ran under `/usr/bin/perl` (v5.34.1); condition 2
        expected Homebrew's Perl and found `/usr/bin/perl (v5.34.1)`; the
        header gave the Perl and the `PATH`; pointer on every failure; exit 1.
- [ ] **AC3. A Perl without the project's modules is reported by the module.**
      The run of AC2 on macOS and Windows; on Linux, `env -u PERL5LIB perl
      process/check-environment.pl`.
      Pass when: condition 3 fails, naming the first module of the host's
      cpanfile that did not load, with its pointer; on Linux condition 5 also
      fails. M L W.
      - M, 2026-10-23, pass (the AC2 run): condition 3 found "Devel::Size does
        not load; 3 of 20 do not: Devel::Size, Text::CSV, Text::CSV_PP", with
        its pointer.
- [x] **AC4. Old bash and the system Python are reported.** macOS:
      `ln -s /bin/bash "$D/bash"; PATH="$D:$PATH" perl
      process/check-environment.pl`, then the same with
      `ln -s /usr/bin/python3 "$D/python3"` in a fresh stand-in directory.
      Pass when: the first run fails condition 6 naming `/bin/bash` and 3.2,
      the second fails condition 7 naming `/usr/bin/python3`, each with its
      pointer, and every other condition reads as in AC1. M.
      - M, 2026-10-23, pass, run twice. On the architect's home, condition 8
        fails in AC1 as well (Homebrew's lines only in `~/.zshrc`), so the
        cases were repeated in a throwaway home whose `.zprofile` holds only
        Homebrew's `eval "$(/opt/homebrew/bin/brew shellenv)"`. There AC1's run
        passes every macOS condition; with the stand-in `bash` only condition 6
        fails, found `<D>/bash -> /bin/bash (3.2)`; with the stand-in
        `python3` only condition 7 fails, found `<D>/python3 ->
        /usr/bin/python3`. Condition 8 passes in both: it judges the login
        shell's tools against what conditions 2, 6 and 7 expect, not against
        the check's own `PATH`.
- [ ] **AC5. The check writes nothing.** `T=$(mktemp -d)`, then, a second
      later, `M=$(mktemp)`; then `HOME="$T" ZDOTDIR="$T" perl
      process/check-environment.pl`, then `find "$T" -newer "$M"` and
      `git status --porcelain`. The mark is made outside the throwaway home
      and after it: made inside it, it leaves the home's directory a few
      microseconds newer than itself, and `find` lists the home on every run
      (measured on macOS, three runs without the check, 2026-10-23).
      Pass when: `find` lists nothing and `git status` is as it was before
      the run. M L W.
      - M, 2026-10-23, pass: `find` listed nothing, `git status` unchanged.

**The session-start check (R3)**

- [ ] **AC6. No Perl on `PATH`.** Link into a stand-in directory only `sh`
      and the commands the hook's launcher calls, then run the hook's command
      as `settings.json` holds it: `env -i PATH="$D" sh -c '<command>'`.
      Pass when: it prints that no Perl was found, the `PATH` it saw and the
      pointer to condition 1's entry, and exits so that the session proceeds.
      M L W.
- [ ] **AC7. A session started on a wrong environment.** From the checkout,
      start Claude Code as `PATH="/usr/bin:/bin:$PATH" claude` (on Windows,
      Git's `/usr/bin` first from Git Bash).
      Pass when: the user sees the failed conditions, each with its pointer;
      asked what the environment check reported, the agent answers from its
      context; and, asked to find the cause, it reads the entries the pointers
      name and identifies the `PATH` order as the cause. M L W.
- [ ] **AC8. The hook is fast enough to run at every session start.** On a
      set-up host, `time sh -c '<command>'`, five runs.
      Pass when: the median is within the budget the architect sets from the
      stage 1 measurement. M L W; unknown until measured.

**Setup (R4, R5)**

- [ ] **AC9. `--repair` and `--validate` install nothing.** In a stand-in
      directory, put a script for each of `brew`, `cpanm`, `apt-get` and
      `winget` that appends its name and arguments to `$D/calls`; the `brew`
      one also passes `--prefix` and `shellenv` on to the real `brew`. Run
      `HOME="$T" ZDOTDIR="$T" PATH="$D:$PATH" <setup> --validate`, then the
      same with `--repair`.
      Pass when: `$D/calls` holds no line other than `brew --prefix` and
      `brew shellenv`. M L W.
- [ ] **AC10. `--repair` adds nothing to a configuration that already works.**
      Seed the throwaway home's shell files with the line `export KEEP=1` and
      the host's own configuration of its tools, as a developer who already
      uses them carries it (macOS: Homebrew's `eval "$(<prefix>/bin/brew
      shellenv)"` in `.zprofile`; Linux and Windows: what stages 2 and 3
      establish), copy the files aside, run `HOME="$T" ZDOTDIR="$T" <setup>
      --repair`, `cmp` each file with its copy.
      Pass when: the check passes and `cmp` reports no difference. M L W.
- [ ] **AC10a. `--repair` adds exactly the missing piece, once.** Seed the
      throwaway home's shell files with `export KEEP=1` only. Run `HOME="$T"
      ZDOTDIR="$T" <setup> --repair`, copy the files aside, run it again, `cmp`
      each file with its copy.
      Pass when: after the first run each file still holds `export KEEP=1`
      unchanged, the check passes, and the only addition is one delimited
      piece for what the check reported missing; after the second run `cmp`
      reports no difference. M L W.
- [ ] **AC11. Every login shell resolves the same tools.** After AC10a's first
      run, for each login mode `-lc` and `-lic`:
      `env -i HOME="$T" ZDOTDIR="$T" zsh <mode> 'command -v perl bash python3'`
      (bash on Linux; on Windows the Git Bash modes stage 3 establishes).
      Pass when: each login mode prints the paths conditions 2, 6 and 7
      expect, and AC10a added nothing to `.zshenv`. M L W.
- [ ] **AC12. The Linux setup works without root for Perl modules.** On a
      Linux host carrying only the distribution's packages, run the Linux
      setup, then `--validate`.
      Pass when: `--validate` exits 0, the project's modules are under
      `~/perl5`, and the setup's output shows no `cpanm` run through `sudo`.
      L.

**The rule (R6, R7, R9)**

- [ ] **AC13. No interpreter named by location.** `git grep -nE 'brew
      --prefix|/opt/homebrew|^#!/usr/bin/perl|(^|[;[:space:]])(export
      +)?PATH=' -- ltl '*.sh' '*.pl' '*.py' build process prototype tests`.
      Pass when: every line it prints is in one of the exceptions or the
      historical records named in § Phase 4: the one rule every script
      follows. M.
- [ ] **AC14. No message about Homebrew where there is none.** On Linux, run
      `prototype/412-notice-surfaces/check-tmux.sh`,
      `prototype/412-notice-surfaces/capture/specimens.sh` and the full harness
      suite of AC16, capturing stderr; `grep -i brew` the captures.
      Pass when: `grep` finds nothing. L.
- [ ] **AC15. `ltl` starts through `env perl`.** `./ltl --version`, and on
      Windows `ls /opt/homebrew/bin/perl`.
      Pass when: `ltl` prints its version on every host, and on Windows `ls`
      reports no such file. M L W.
- [ ] **AC16. The harness suite passes.** The completion gate's full suite
      (`docs/process/workflow.md` § 3). Pass when: every harness passes. M L.

**Profiling and packaging (R8)**

- [ ] **AC17. `--dev-deps` installs the profiler on Windows.**
      `build/windows-setup.ps1 --dev-deps`, then from Git Bash
      `perl -MDevel::NYTProf -e 1`. Pass when: exit 0. W.
- [ ] **AC18. Profiling runs on Windows.** `tests/profile/run-profile.sh`
      from Git Bash. Pass when: it writes its report. W; unknown: whether the
      profiling scripts meet the Windows traps that stop the harnesses there
      is stage 3's to find.
- [ ] **AC19. No binary carries the profiler.** With the develop block in the
      cpanfile and the profiler installed, build each binary and list its
      archive (`unzip -l <binary>`). Pass when: no entry names
      `Devel/NYTProf`. M C.

**The records (R10)**

- [ ] **AC20. The instructions name the setup, not a `PATH` line.**
      `git grep -n 'brew --prefix\|opt/homebrew' -- README.md CLAUDE.md
      docs/toolchain-guidance.md`, then read each host's setup instructions.
      Pass when: `git grep` finds nothing, and each host's instructions name
      its setup with `--repair` and `--validate`. M.

## Stage 1 implementation plan (macOS development host)

Written 2026-10-23 from the requirements, decisions and conditions above. One
commit per step, pushed to `750-interpreter-resolution`; each test case's
result is recorded under it, with host and date, as it is run. Stages 2 to 4
(Linux, Windows, the container builds) are planned on their hosts.

### Step 0: the `before` benchmark

The diff will touch `tests/validate-*.sh` and `tests/lib/`, so the completion
gate requires a before/after benchmark (`docs/process/workflow.md` § 3).
`./tests/baseline/run-benchmark.sh single-day-access-log-standard --label
750-before`, run in the background from the `release/0.20.0` worktree at
`7d0b57f8`, the issue's base, a worktree beside the issue's own, so both sides
run from the same kind of checkout.

Done 2026-10-23: `tests/baseline/results/750-before.tsv` in the
`release/0.20.0` worktree at `7d0b57f8`.

### Step 1: `process/check-environment.pl`

- `#!/usr/bin/env perl`, `use strict; use warnings;`, core modules only
  (`Config`, `Cwd`, `File::Spec`, `JSON::PP`), no syntax newer than the
  oldest Perl it must run under (Ubuntu 20.04's 5.30), so the macOS system
  Perl, Git for Windows' Perl and a distribution's Perl all run it (R2).
- **Host** from `$^O`: `darwin` macOS, `linux` Linux, `msys`, `cygwin` and
  `MSWin32` Windows.
- **One list of conditions** (D1): an array of entries, each with its number,
  title, severity, and one test per host or `n/a`. A test returns the result,
  what it expected and what it found.
- **Three helpers, used by every test:** `find_on_path(name)` (splits `PATH`
  on `$Config{path_sep}`), `real(path)` (`Cwd::abs_path`, so a Homebrew link
  resolves into its Cellar), and `run_capture(cmd...)`, the one place a tool
  is started, so stage 3 adapts one sub for Strawberry Perl.
- **The tests, macOS column** (Linux and Windows columns written from the
  conditions table, validated in their stages):

  | # | Test |
  |---|---|
  | 1 | `find_on_path('perl')` |
  | 2 | `real()` of it contains `/Cellar/perl/` (Homebrew, whatever the prefix) |
  | 3 | `build/cpanfile`'s `requires` lines outside the `on 'develop'` block; the Perl found on `PATH` requires each and prints those that fail; found names the first and the count |
  | 4 | the same for the develop block; note |
  | 5 | n/a (Linux: `PERL5LIB` carries `$HOME/perl5`) |
  | 6 | `bash -c 'echo ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}'` is 4 or later, and `real()` of it is in a Cellar |
  | 7 | `python3 -B -c 'import numpy, scipy'` succeeds (`-B` writes no bytecode), and `real()` of it is in a Cellar |
  | 8 | `env -i HOME USER LOGNAME TERM` (and `ZDOTDIR` when set) `/bin/zsh -lc` printing `command -v` of `perl`, `bash`, `python3`; each tool it resolves passes the test of condition 2, 6 or 7, whatever the check's own `PATH` holds (AC4, AC11). Also run, shown and not judged: `-lic` (a new tab) and `-c` (a plain shell) |
  | 9 | `tmux` on `PATH`; note |
  | 10 | `swiftc` on `PATH`; note |
  | 11 | n/a (Windows: `git config core.autocrlf` is `false`) |

- **Report** (R1, D11): a header with the host, the Perl it ran under (`$^X`,
  version) and the `PATH` it saw; then per condition its number, `pass`,
  `FAIL`, `note` or `n/a`, the title, and for every condition not passing the
  expected and found lines and `see: features/750-interpreter-resolution.md
  § Troubleshooting a failed condition, <n>`; a last line counting each
  result. Exit 0 with no `FAIL`, 1 with any, 2 on a usage error.
- **Options:** `--hook` prints the SessionStart JSON
  (`hookSpecificOutput.additionalContext` carries the whole report; a
  `systemMessage` lists each failed condition with its pointer, and is absent
  when nothing fails) and exits 0; `--condition N[,N...]` runs only those
  conditions, for the profiling preflight (step 4); `-h`, `--help`. An unknown
  option prints usage to stderr and exits 2 having tested nothing.
- **Proven by** AC2 (the wrong Perl first), AC3 (a Perl without the modules),
  AC4 (old bash; the system Python), AC5 (writes nothing). AC1 waits for
  step 3's `--validate`.

### Step 2: the session-start hook

- A second entry under `SessionStart` in `.claude/settings.json` (D8), with
  the same matcher as the outstanding-state sweep (`startup|resume|clear|compact`,
  so the report survives a cleared context) and a 60 s timeout. Its command,
  in shell form (D2):
  `command -v perl >/dev/null 2>&1 && exec perl
  "$CLAUDE_PROJECT_DIR/process/check-environment.pl" --hook`, else a `printf`
  of the SessionStart JSON saying no Perl was found, with the `PATH` it saw
  and condition 1's pointer. A `PATH` holding a double quote or a backslash
  makes that JSON invalid, and Claude Code then takes it as plain text into
  the context; accepted, as no development host's `PATH` carries either.
- **Proven by** AC6 (no Perl on `PATH`), and AC8: five timed runs, the
  median brought to the architect to set the budget.

### Step 3: `build/macos-setup.sh`

- Stays `#!/bin/bash` and bash 3.2 compatible: it runs before Homebrew bash
  exists. As a setup script it is one of the rule's exceptions.
- **Options** (D9): `--dev-deps`, `--package`, `--repair`, `--validate`,
  `-h`/`--help`. `--repair` and `--validate` take no other option; an unknown
  option or a forbidden pair prints usage and exits 2 having done nothing.
- **`--validate`:** runs `perl process/check-environment.pl` with the
  caller's `PATH`, and exits with its status. No `brew` call.
- **Homebrew is required** (D13): the full setup and `--repair` stop when
  `brew` is not on `PATH`, as today.
- **Full setup:** `brew install perl bash python numpy scipy cpanminus`;
  PAR::Packer only under `--package`; `./generate-cpanfile.sh`; `cpanm
  --notest --installdeps .`, with `--with-develop` under `--dev-deps`; the
  `PATH` exports and `GITHUB_PATH` lines for its own run and CI as today; then
  the shell step, then the check, exiting with its status.
- **The shell step** (`--repair`, and the full setup's; D12, D6): run the
  check; when condition 8 passes, add nothing. When it fails, read a clean
  login shell's `PATH` (`env -i … /bin/zsh -lc 'echo $PATH'`): if
  `$(brew --prefix)/bin` is absent from it, Homebrew's line is the missing
  piece, and it is appended once to `${ZDOTDIR:-$HOME}/.zprofile` between the
  markers the Windows setup already uses (`# >>> ltl homebrew >>>`,
  `# <<< ltl homebrew <<<`), as `eval "$(<prefix>/bin/brew shellenv)"` with
  the prefix written out. If the markers are already there, or Homebrew's
  `bin` is on that `PATH` but behind other entries, nothing is added: the
  cause lies in a line the user owns, and the check's report shows it. Then
  run the check again.
- **The Perl keg line:** with PAR::Packer installed for Homebrew Perl (this
  host has none for 5.44; asked of the architect before installing), build the
  binary from a clean login shell carrying only Homebrew's line
  (`build/macos-package.sh arm64`, which runs `perl -S pp`), and see which
  `pp` it starts and whether the binary runs. The keg line becomes a second
  piece of the shell step only if this shows it is needed.
- **CI:** `.github/workflows/release-build.yml` runs
  `./build/macos-setup.sh --package`. Verified by a manual run of that
  workflow on the issue branch (its release job runs on tags only), asked of
  the architect first.
- **Proven by** AC9 (`--validate` and `--repair` install nothing), AC10 (a
  working configuration gains nothing), AC10a (the missing piece added once),
  AC11 (both login modes resolve the tools), each in a throwaway home.

### Step 4: the one rule, applied

- `ltl` line 1 `#!/usr/bin/env perl`.
- The 15 harnesses: `PERL="${PERL:-perl}"`, and the fallback line after it
  removed; the comment in `tests/validate-section-layout.sh` that names
  Homebrew Perl rewritten to the rule.
- `prototype/`: the seven `#!/usr/bin/perl` first lines to `env perl`; bare
  `perl` in `prototype/426-asbuilt-run.sh`; the `PATH` lines removed from the
  two notice-surface scripts. `tests/profile/checks/README.md`: bare `perl`.
- `tests/lib/require-bash.sh`: the remedy line names, by `uname -s`, the
  host's setup with `--validate` (macOS: `build/macos-setup.sh --validate`;
  elsewhere, until stage 2 names the Linux setup, `perl
  process/check-environment.pl`); its header comment rewritten the same way.
- `tests/profile/profiling-preflight.sh`: its check 1, a second test for
  "not the system Perl" that names `/usr/bin` and so would fail on Linux,
  where `/usr/bin/perl` is the expected Perl, becomes a call of
  `process/check-environment.pl --condition 1,2`, keeping its exit code 1;
  its remedy names the host's setup as `require-bash.sh` does. Its one
  consumer, `tests/profile/run-profile.sh`, reads only the exit code.
- Records (R10): `README.md` § Install Dependencies (macOS requires Homebrew;
  the setup, `--repair`, `--validate`), § Test-harness dependencies (the
  `export PATH` block gives way to `--validate`), the profiling subsection
  (`--dev-deps` for `LTL_INSTALL_DEV_DEPS=1`); `CLAUDE.md` § Build and § Test
  and benchmark; `tests/HARNESS-DESIGN.md`'s note on Homebrew bash; 544 D1 and
  D7 restated against the requirement. `docs/toolchain-guidance.md` §
  Windows development host waits for stage 3, which changes what it describes.
- **Proven by** AC13 (the search for interpreters named by location), AC15
  (`./ltl --version`), AC20 on `README.md` and `CLAUDE.md` (the Windows
  section's line waits for stage 3); `perl -c` and `bash -n` on each changed
  script; one scenario of a changed harness run before and after, with the
  `perl` each one starts read from its output.

### Step 5: this host

- `build/macos-setup.sh --validate` on the architect's own home: condition 8
  is expected to fail (§ Phase 4: what Homebrew's own configuration already
  provides on macOS). Moving the `~/.zshrc` lines, or running `--repair`, is
  the architect's choice; then AC1.
- AC7, a session started on a wrong `PATH`, is run by the architect.

### Not in stage 1

The full harness suite runs once, at the completion gate after stage 4, on
this host; AC16's macOS result is recorded there. Linux setup, the Windows
setup's options and modes, the shim's removal, and the container builds
belong to stages 2 to 4.

## Troubleshooting a failed condition

The check points here (D11). It reports what it expected, what it found, the
Perl it ran under and the `PATH` it saw; it does not say what to do. Work out
the cause on the host from what the report shows and what each entry below
says, then fix the cause, not the symptom: no script is edited to name an
interpreter, and no `PATH` line is added by hand outside setup's managed
block.

Two things hold for every entry:

- **The check sees the environment of whatever started it.** At session start
  that is Claude Code's own process, inherited from the shell Claude Code was
  started from, not the agent's Bash tool snapshot and not a fresh terminal
  (§ How Claude Code runs a hook). A condition can fail in the session and
  pass in a new terminal, or the reverse; compare the `PATH` the report gives
  with the one in a new terminal before concluding anything.
- **Which shell files are read depends on how the shell was started.**
  § Phase 1 lists the contexts measured on macOS and how each gets its
  `PATH`; § Phase 4: where macOS setup writes its shell configuration shows
  which file each zsh mode reads. A context that reads none of setup's files
  resolves the system's tools.

| # | What a failure means | Where it has come from, and where to look |
|---|---|---|
| 1 | no `perl` on the `PATH` the check saw | the host is not set up, or the process that started the check did not inherit the setup's `PATH` (a Windows host without Git Bash, where Claude Code falls back to PowerShell, is treated as not set up) |
| 2 | another Perl comes first | `PATH` order: Homebrew's line, or setup's addition, missing from a file this context reads (condition 8 shows which shell modes resolve what), or a later line in a shell file, or `path_helper` on macOS, putting the system directories back in front; on Windows, Git's `/usr/bin` ahead of Strawberry Perl |
| 3 | the right Perl lacks a runtime module | the Perl is right but its modules are not where it looks: on macOS, a Homebrew Perl upgrade across a minor version leaves the modules installed for the old one behind (`features/544-upgrade-safe-profiling-setup.md` § Machine state and mechanism); a cpanfile changed since setup ran; on Windows, `build/cpanfile.windows` differs from `build/cpanfile`. Installing is the full setup's job, not `--repair`'s |
| 4 | note: the profiler is not installed | expected unless setup ran with `--dev-deps`; the same upgrade cause as 3 applies |
| 5 | Linux: `PERL5LIB` does not carry `~/perl5` | the line that sets it missing from a file this context reads, as for 2 |
| 6 | the first `bash` is older than 4 | the system's bash ahead of the setup's; macOS's `/bin/bash` is 3.2. Same `PATH` causes as 2 |
| 7 | `python3` does not import NumPy or SciPy | another Python ahead of the setup's (macOS `/usr/bin/python3`; on Windows the Microsoft Store stub), or the modules installed for a different Python than the one on `PATH` |
| 8 | a login shell from a clean environment resolves different tools | the lines that put the tools first are in a file a login shell does not read (on macOS, `~/.zshrc` alone, which only an interactive shell reads: the report then shows a new tab right and a login shell wrong), or another file read after them reorders `PATH`; compare the modes as § Phase 4: where macOS setup writes its shell configuration did. `--repair` adds the missing piece to `~/.zprofile` |
| 9 | note: no `tmux` | the terminal-interface navigation tests cannot run on this host |
| 10 | note: no screenshot tools | screenshot capture cannot run on this host |
| 11 | Windows: `core.autocrlf` is not `false` | the clone was made without `-c core.autocrlf=false`, or a global setting overrides the repository's; scripts check out with CRLF endings and fail in Git Bash |
