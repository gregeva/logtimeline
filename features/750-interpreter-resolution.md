# 750: scripts find bash and Perl from the environment the setup prepared

Issue: #750 (scripts set their own PATH from `brew --prefix`, which works around
the environment setup and fails where Homebrew is absent). Parent: #729
(process, tests and build).

Status: specification, analysis. What is in place today is recorded as found,
not as the contract: most of it was put in piecemeal to get past a problem at
the time, and the analysis is expected to challenge it.

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
| 8 | the shell configuration carries the setup's managed block | the file every login zsh reads | the file every login bash reads | `~/.bashrc`, read by `~/.bash_profile` | fail |
| 9 | a login shell started from a clean environment resolves the same `perl`, `bash` and `python3` as conditions 2, 6 and 7 | | | | fail |
| 10 | `tmux` is on `PATH` | expected | expected | not expected | note |
| 11 | the screenshot tools are present | `swiftc` (Xcode command line tools) | established in the Linux stage | not expected | note |
| 12 | the repository checks files out with LF endings | n/a | n/a | `core.autocrlf=false` | fail |

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

Condition 9 is the measured fault of phase 1: the Homebrew interpreters were
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
meets condition 9 in every mode, so macOS setup writes its managed block into
both `~/.zshenv` and `~/.zprofile`.

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
| full setup (no switch) | yes | yes | yes, last |
| `--repair` | no | yes, the managed blocks only | yes, after writing |
| `--validate` | no | no | yes |

`--repair` cannot install or upgrade anything by construction; it is what the
check names when a condition about the shell configuration fails. Making the
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
| `--repair` | write the shell configuration only, then run the check | |
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
| `#!/usr/bin/perl` in five prototype scripts, `/opt/homebrew/bin/perl` in `prototype/426-asbuilt-run.sh` | `env perl`, bare `perl` |
| the example in `tests/profile/checks/README.md` | bare `perl` |
| the `export PATH="$(brew --prefix)..."` lines in `CLAUDE.md` and `README.md` | the host's setup, and its `--validate` |
| `require-bash.sh`'s Homebrew hint | names the host's setup and `--validate` |
| historical records (`tests/profile/results/*`, `releases/*`, past investigations) | untouched: they record the interpreter of their time |

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

Draft, for the architect's review.

- **R1. One environment check.** A single Perl script tests the twelve
  conditions of § Phase 4: the expected conditions, and reports each one by
  number with its result (pass, fail, note), what it found (the path and
  version of the tool on `PATH`, the module that did not load) and the remedy
  for the host it runs on. It is read-only: it installs, writes and changes
  nothing.
- **R2. The check runs before setup.** It uses core Perl modules only, so any
  Perl runs it: the macOS system Perl, Git for Windows' own Perl, a
  distribution's Perl. It tests the tools it finds on `PATH` by starting them,
  never the Perl it runs under.
- **R3. A session-start check.** A shell-form SessionStart hook runs a few
  lines of `sh`: with a `perl` on `PATH` it runs the check, without one it
  reports that no Perl was found and names the host's setup. The report goes
  into the model's context; a failed condition is also shown to the user.
  The session always proceeds. It is its own hook entry, beside the
  outstanding-state sweep of `process/claude-hooks/session-start.sh`.
- **R4. Three setup modes on every host.** `build/macos-setup.sh`,
  `build/windows-setup.ps1` and a new Linux setup script each have a full
  setup, `--repair` and `--validate` (§ Phase 4: re-running setup is not safe
  for the shell configuration). `--repair` and `--validate` install and
  upgrade nothing. The full setup ends by running the check. All three take
  the one option set of § Phase 4: one option set for every setup script.
- **R5. Setup owns the shell configuration.** Each setup writes one managed
  block, delimited so that rewriting it leaves everything else in the file
  untouched: macOS into `~/.zshenv` and `~/.zprofile` (measured, § Phase 4:
  where macOS setup writes its shell configuration), Linux into the files its
  stage establishes, Windows into `~/.bashrc`, as today. Writing it again
  changes nothing.
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
| D1 | One read-only check, in Perl, one list of conditions with per-host alternatives; the twelve conditions as listed | architect |
| D2 | The session-start hook: shell form, an `sh` launcher, the Perl check | architect |
| D3 | Linux starts from the distribution's Perl with `local::lib`; not a hard requirement, settled in the Linux stage | architect |
| D4 | Setup modes: full, `--repair`, `--validate` | architect |
| D9 | One option set on every setup script: `--dev-deps`, `--package`, `--repair`, `--validate`, `-h`/`--help`; CI's macOS step runs `--package`; 544 D6's environment variable goes | architect |
| D5 | Profiling on every host; 544 D5a amended | architect |
| D6 | macOS writes its block into both `~/.zshenv` and `~/.zprofile` | delegated, from the measurement |
| D7 | The one rule and its exceptions; `require-bash.sh` stays as a guard with a host-neutral message | delegated |
| D8 | The environment check is its own SessionStart hook entry | delegated |

## Acceptance criteria

Draft, for the architect's review. Each names the hosts it is validated on
(M macOS, L Linux, W Windows, C the container builds) and its triage.
"Throwaway home" means a temporary `HOME` (and `ZDOTDIR`) so the developer's
own files are never touched.

**The check (R1, R2)**

- [ ] **AC1.** `--validate` on a set-up host reports all twelve conditions by
      number, every applicable one passing, and exits 0. M L W; assertable.
- [ ] **AC2.** Started under the wrong Perl, the check still runs and fails
      condition 2 naming the Perl it found: `/usr/bin/perl` on macOS, Git's
      own Perl on Windows. M W; assertable.
- [ ] **AC3.** With a `PATH` whose first `perl` lacks the project's modules,
      condition 3 fails and names the first module that did not load. M L W;
      assertable (on macOS the system Perl is that Perl).
- [ ] **AC4.** With `bash` 3.2 first on `PATH` (macOS `/bin/bash`),
      condition 6 fails; with `/usr/bin/python3` first, condition 7 fails. M;
      assertable.
- [ ] **AC5.** The check writes nothing: run in a throwaway home, no file
      under it or under the checkout is created or changed. M L W; assertable.

**The session-start check (R3)**

- [ ] **AC6.** The hook's command, run with a `PATH` holding `sh` but no
      `perl`, prints the no-Perl message naming the host's setup and lets the
      session proceed. M L W; assertable (a directory of links to the few
      tools `sh` needs).
- [ ] **AC7.** In a session started with a failing condition, the user sees
      the failed condition and its remedy, and the model's context carries
      the report. M L W; observed by hand once per host (Claude Code's display
      is not scriptable here).
- [ ] **AC8.** The hook's wall time on a set-up host is within a budget the
      architect sets from a measurement taken in stage 1. M L W; unknown until
      measured.

**Setup (R4, R5)**

- [ ] **AC9.** `--validate` and `--repair` start no installer: run with
      stand-ins for `brew`, `cpanm`, `apt-get` and `winget` on `PATH` that
      record each call, they record none apart from read-only queries
      (`brew --prefix`). M L W; assertable.
- [ ] **AC10.** In a throwaway home, `--repair` run twice leaves each shell
      file byte-identical after the second run, and lines outside the managed
      block are unchanged after the first. M L W; assertable.
- [ ] **AC11.** After `--repair` in a throwaway home, a shell started from a
      clean environment in each mode (`-c`, `-lc`, `-ic`, `-lic`) resolves the
      same `perl`, `bash` and `python3` that conditions 2, 6 and 7 expect.
      M L (W: Git Bash login and non-login); assertable.
- [ ] **AC12.** The new Linux setup brings a Linux host from the
      distribution's packages to `--validate` passing, without installing a
      Perl module as root. L; assertable in stage 2.

**The rule (R6, R7, R9)**

- [ ] **AC13.** `git grep` over the tracked scripts (`ltl`, `*.sh`, `*.pl`,
      `*.py`, `build/*`, `process/*`, `prototype/*`) outside the named
      exceptions and the historical records finds no `brew --prefix`, no
      `/opt/homebrew`, no `#!/usr/bin/perl`, and no assignment to `PATH`.
      M; assertable.
- [ ] **AC14.** On a host without Homebrew, `prototype/412-notice-surfaces/check-tmux.sh`,
      `prototype/412-notice-surfaces/capture/specimens.sh` and every harness
      print nothing on stderr naming `brew`. L; assertable.
- [ ] **AC15.** `./ltl --version` runs on each host through `env perl`, on
      Windows with no shim at Git's `/opt/homebrew/bin/perl`. M L W;
      assertable.
- [ ] **AC16.** The full harness suite passes on macOS and on Linux after the
      change. M L; assertable (the completion gate, run on both).

**Profiling and packaging (R8)**

- [ ] **AC17.** On Windows, `build/windows-setup.ps1 --dev-deps` leaves
      `perl -MDevel::NYTProf -e 1` succeeding. W; assertable in stage 3.
- [ ] **AC18.** A profiling run (`tests/profile/run-profile.sh`) produces its
      report on Windows. W; unknown: whether the profiling scripts meet the
      Windows traps that stop the harnesses there is stage 3's to find.
- [ ] **AC19.** No packaged binary carries the profiler: the archive listing
      of each binary built with the develop block present names no
      `Devel/NYTProf`. M C; assertable in stages 1 and 4.

**The records (R10)**

- [ ] **AC20.** `README.md`, `CLAUDE.md` and `docs/toolchain-guidance.md`
      carry no `export PATH="$(brew --prefix)` line and no shim, and name
      each host's setup with `--repair` and `--validate`. M; assertable by
      `git grep` and by reading.

**Proposal for the architect's decision (proportionality):** AC1 to AC6 and
AC9 to AC11 can be gathered into one harness, `tests/validate-environment.sh`,
whose scenarios build stand-in `PATH` directories and a throwaway home; it
runs on macOS and Linux. Without it, they are checked by hand at each stage
and recorded here.
