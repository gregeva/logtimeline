# 750: scripts find bash and Perl from the environment the setup prepared

Issue: #750 (scripts set their own PATH from `brew --prefix`, which works around
the environment setup and fails where Homebrew is absent). Parent: #729
(process, tests and build).

Status: in progress, on the issue branch `750-interpreter-resolution`.
Stage 1 (the macOS development host) and stage 2 (the Linux development
host) complete on 2026-10-23; stage 3 needs the Windows development host.
Each test case run on macOS and Linux is recorded under it; § Resuming says where to start, what stage 1
leaves to the later stages, and the state this work left outside the
repository. What is in place before this work is recorded as found, not as
the contract: most of it was put in piecemeal to get past a problem at the
time, and the analysis is expected to challenge it.

## Resuming

Stages 1 and 2 have nothing open. Stage 2 (§ Stage 2: the Linux development
host) settled D3 as the distribution's packages, wrote
`build/linux-setup.sh`, retired condition 5, and ran every Linux test case.

**Next: stage 3, on the Windows development host.** Check out
`750-interpreter-resolution`, read this document, and plan the stage there
before taking its steps (§ Phase 4: investigation stages, one per
environment): run `perl process/check-environment.pl` first and record what
the Windows column reports on a host as found. The standing description of
the check, the setup per host and the troubleshooting entries is
`docs/development-environment.md`.

Stages 3 (Windows) and 4 (the container builds) are each planned on their own
host before their steps are taken. What stages 1 and 2 leave to them (the
Linux items below are done in stage 2):

- `process/check-environment.pl` has its Linux and Windows columns written
  from the conditions table and not yet run; `run_capture` is the one place a
  tool is started, for stage 3 to adapt to Strawberry Perl. Condition 7's
  user-site and installed-twice tests (D15) run on every host; its `modules`
  place test exists for macOS only. Stages 2 and 3 run their host's column
  of § Phase 4: investigation stages, one tool or module installed two ways,
  under AC3a, AC4a and AC10b, and stage 3 closes the Windows gap named there (an
  interpreter judged by its wrapper's path).
- Condition 3's core directories (D16) count any built-in `@INC` directory
  holding `strict.pm` as core, so Debian's `perl-base` is core: read, not
  measured; stage 2 confirms it. `run_capture` starts each tool with
  `POSIX::setsid`, which Strawberry Perl may not provide; stage 3 adapts it.
- `docs/development-environment.md`'s Linux and Windows rows gain each
  setup's `--repair` and `--validate` as stages 2 and 3 write them, and the
  session-start message (`user_message` in the check) names those commands.
- `README.md`'s Linux and Windows instructions, and `docs/toolchain-guidance.md`
  § Windows development host (trap 3, the shim at Git's
  `/opt/homebrew/bin/perl`, now unused by `./ltl`), are stages 2 and 3's to
  rewrite; AC20 completes in stage 3.
- The profiling preflight names a remedy for a missing `cpanm` on macOS
  only, until stages 2 and 3 give the other hosts a setup.

The completion gate runs once, after stage 4, on the macOS development host
where the `before` benchmark was captured (`docs/process/workflow.md` § 3): the
`after` benchmark (`./tests/baseline/run-benchmark.sh
single-day-access-log-standard --label 750-after`) from a worktree beside the
`release/0.20.0` one, so both sides run from the same kind of checkout,
compared with `750-before.tsv`; then the full harness suite (AC16).

State outside the repository, on the first macOS development host only (the
one the keg measurement was parked from):

- `tests/baseline/results/750-before.tsv`, untracked, in the `release/0.20.0`
  worktree (`.claude/worktrees/release-0.20.0`), captured at `7d0b57f8`. The
  `after` side needs this machine.
- `~/.zprofile`, created by `--repair` in step 5, holding the one marked
  Homebrew block.
- PAR::Packer is not installed for Homebrew Perl 5.44.

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
| 3 | it loads every runtime module the cpanfile requires, each from the Perl's own install or the setup's, once (D16) | `build/cpanfile` | `build/cpanfile` | `build/cpanfile.windows` | fail |
| 4 | it loads the development-only modules (the profiler) | when installed (`--dev-deps`) | when installed (`--dev-deps`) | when installed (`--dev-deps`), once `build/cpanfile.windows` carries the develop block (544 D5a as amended) | note |
| 5 | retired under D3 as settled in stage 2: no setup installs modules under the home | | | | |
| 6 | `bash` on `PATH` is 4 or later | Homebrew's | the distribution's | Git Bash | fail |
| 7 | `python3` on `PATH` imports NumPy and SciPy, each from the setup's install (D15) | Homebrew's, not `/usr/bin/python3`; each module's file resolves into its own formula's Cellar; on every host, neither module from the user's `site-packages` nor installed more than once | the distribution's; NumPy and SciPy from its packages, in `/usr/lib/python3/dist-packages` (D3) | the WinGet Python; the modules' place established in the Windows stage | fail where the harnesses run, note on Windows |
| 8 | a login shell started from a clean environment resolves the same `perl`, `bash` and `python3` as conditions 2, 6 and 7; the report also shows, for context, what a new terminal tab (an interactive login shell) and a plain non-login shell resolve | `zsh -lc`; `~/.zprofile` (D6) | a login bash | a Git Bash login shell | fail |
| 9 | `tmux` is on `PATH` | expected | expected | not expected | note |
| 10 | the screenshot tools are present | `swiftc` (Xcode command line tools) | not expected: the PNG is drawn by WebKit on macOS (`features/598-screenshot-capture.md` D23) | not expected | note |
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
  shell, inside a session or not. Its message points at the environment
  check, the same line on every host, not at Homebrew.

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
| `require-bash.sh`'s Homebrew hint | points at the environment check: `perl process/check-environment.pl` |
| `#!/bin/bash`, bash 3.2 on macOS, in 18 scripts: `build/generate-cpanfile.sh`, `build/install-deps.sh`, `build/macos-package.sh`, `tests/baseline/run-benchmark.sh`, `tests/baseline/compare-results.sh`, `tests/profile/run-profile.sh`, `tests/profile/profiling-preflight.sh`, and 11 prototype scripts | `#!/usr/bin/env bash`. `build/macos-setup.sh` and the two container builds keep it, as exceptions |
| the Python install hints in `tests/validate-statistics.sh`, `tests/validate-profile.sh`, `tests/validate-distribution-shape.sh` and `tests/distribution-shape/generate-anchor.py`, which printed a macOS `brew` remedy on every host and advised installing into the command-line-tools Python or a `PATH` change | point at the environment check and at `README.md` § Test-harness dependencies, the same two lines on every host |
| the macOS bullets of `tests/statistics-drift/README.md` § External dependencies, naming Homebrew's and the command-line-tools Python by path | the macOS setup and its `--validate` |
| historical records (`tests/profile/results/*`, `releases/*`, past investigations, `build/packaging-notes`, the prototype reports that name the Perl they ran under) | untouched: they record the interpreter of their time |
| `prototype/720-packed-generated-loop/pack-windows.sh`, which sets `PATH` to Strawberry Perl inside its Wine container | untouched: the container steps of `build/windows-package.sh`, a sealed environment |
| `tests/validate-screenshot-capture.sh`, which runs the capture tool with `PATH` cut down to a directory without the tools | untouched: the test's own fixture for an absent tool |

Stage 1 audit (2026-10-23): the AC13 search over the issue branch at
`54b29fe2` printed 52 lines; beyond the inventory above it found
`#!/usr/bin/perl` in `prototype/colors` and `prototype/colors-256`, added to the
prototype row, and the three untouched rows just above.

Stage 1 step 4 (2026-10-23): a census of every tracked file's first line
found `#!/bin/bash` in 22 scripts, which AC13's pattern did not search for:
the 18 of the row above, the three exceptions, and one under
`tests/profile/results/`, a historical record. AC13's pattern gains
`^#!/bin/bash`. The rule already covered them (architect, 2026-10-23: more
sites, the same decision). Also found: `#!/bin/zsh` in
`prototype/426-revalidate-v2.sh` and `#!/bin/sh` in
`prototype/426-revalidate-v5-run.sh`, left as they are: neither is one of the
three interpreters the rule governs, and each names the only one of its kind
on the host.

### Phase 4: investigation stages, one per environment

Each stage runs on the host it is for, tries the setup and the check there, and
records what it finds here before the next.

| Stage | Host | What it establishes |
|---|---|---|
| 1 | macOS development host | the check script, the session-start hook, `build/macos-setup.sh` with `--repair` and `--validate`, the rule applied to every script |
| 2 | Linux development host | a new Linux setup script (the distribution's packages, D3), the check's Linux column, the screenshot tools on Linux (not expected), every harness starting under it (AC16) |
| 3 | Windows development host | `build/windows-setup.ps1` with `--repair` and `--validate`, the check under Git Bash, `./ltl` through `env perl` with no shim, the hooks, the profiler with `--dev-deps`, the option set parsed by PowerShell |
| 4 | the container builds | `build/windows-package.sh` (Wine) and `build/ubuntu-package.sh` build as before, with the develop block in `build/cpanfile.windows` |

**One tool or module installed two ways: what detects it on each host.**
Found on a second macOS host whose Python was set up by hand (§ Step 5, the
second host): a check that a tool runs and a module imports passes while the
copy that wins is not the setup's. The check detects the class on every host
now, without waiting for a stage to find it there: for Python, a module from
the user's `site-packages` and a module installed more than once fail
condition 7 on every host (D15); for Perl, a module from outside the Perl's built-in `@INC` and the setup's directory, or with two copies outside the core, fails condition 3 on every host (D16); and each host's place test adds what only
that host's layout can tell. The forms for Linux and Windows are read, not
measured; stages 2 and 3 run them on their hosts under AC3a, AC4a and AC10b. Stage
4's containers run no harness and install into a fresh image, so none of
these forms arises there.

| Form | macOS | Linux | Windows | Detected by |
|---|---|---|---|---|
| another interpreter comes first | Homebrew's Python only as a versioned formula, so no `python3` link and `/usr/bin/python3` first (measured) | a `python3` from pyenv, conda or Homebrew on Linux ahead of the distribution's | another Python ahead of the setup's; the Microsoft Store stub | the place test of condition 7 on macOS and Linux; on Windows, an import failing (the stub runs no Python). **Not detected on Windows:** another Python that imports both modules, since `python3` there is setup's wrapper script in `~/bin` and the place test reads the path, not the interpreter the wrapper starts; stage 3 |
| a module installed outside the setup's install shadows the setup's | `pip` into Homebrew Python's `site-packages` (measured) | `pip install --user` over the distribution's packages | `pip install --user` over the install's own `site-packages` | every host: a module from the user's `site-packages`; a module installed more than once. macOS also: a module outside its formula's Cellar |
| a stale copy left beside the setup's | `pip`'s NumPy metadata left under Homebrew's files (measured) | a `pip` copy beside the distribution's package | a second copy after a reinstall | every host: a module installed more than once |
| the setup's package installed but not in effect | a formula installed but not linked (measured) | the distribution's package present, another copy first | modules installed for one Python while `PATH` reaches another | every host: an import failing, or a module installed more than once; macOS setup's link step names the files in the way |
| the setup's default moved past what is installed | Homebrew's `python` alias names 3.15 while the modules were on 3.14 (measured) | a distribution upgrade changing `python3`'s minor version | WinGet upgrading Python, leaving the modules on the old one | every host: an import failing on the Python now first |
| the same for Perl | a Homebrew Perl upgrade across a minor version leaving the modules in the old keg (`features/544-upgrade-safe-profiling-setup.md` § Machine state and mechanism) | a module in `~/perl5` and the distribution's `lib*-perl` package at different versions | Strawberry Perl reinstalled, its `site\lib` from the earlier one | every host: condition 3 when a module no longer loads, loads from outside the Perl's built-in `@INC` and the setup's directory, or has two copies outside the core (D16) |

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
- **Several hooks for one event** (read 2026-10-23): "When an event fires,
  its matching hooks run in parallel." "When several hooks return
  `additionalContext` for the same event, Claude receives all of the values."
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
| `tests/distribution-shape/generate-anchor.py`, the Python hints in `tests/validate-statistics.sh`, `tests/validate-profile.sh`, `tests/validate-distribution-shape.sh` | first dismissed, as labelled with the platform each is for; rewritten in stage 1 step 4 under R7 and R9 (§ Phase 4: the one rule every script follows) |
| #106, #138, #328, #434, #541 | dismissed: closed, matched a term in passing |


## Requirements

Written in the specification stage; the architect closed the stage without a line-by-line review (2026-10-23).

- **R1. One environment check.** A single Perl script tests the eleven
  conditions of § Phase 4: the expected conditions, and reports each one by
  number with its result (pass, fail, note), what it expected on this host,
  what it found (the path and version of the tool on `PATH`, the module that
  did not load), the context it ran in (the Perl it ran under, the `PATH` it
  saw), and, for every condition not passing, a pointer to that condition's
  entry in `docs/development-environment.md` § Troubleshooting a failed
  condition. It does not
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
| D3 | Linux takes everything from the distribution's packages: its Perl, a `lib*-perl` package per cpanfile module, `python3-numpy` and `python3-scipy`; no `local::lib`, no `~/perl5`, no `PERL5LIB`, nothing added to the shell configuration. Condition 5 (`PERL5LIB` carries `~/perl5`) is retired, its number not reused; D16's setup directory is none on any host. Settled by the architect in stage 2 (2026-10-23), replacing the first wording (the distribution's Perl with `local::lib`) | architect |
| D4 | Setup modes: full, `--repair`, `--validate` | architect |
| D9 | One option set on every setup script: `--dev-deps`, `--package`, `--repair`, `--validate`, `-h`/`--help`; CI's macOS step runs `--package`; 544 D6's environment variable goes | architect |
| D5 | Profiling on every host; 544 D5a amended | architect |
| D6 | The development tools must resolve in every login shell, as Homebrew advises; on macOS the place is `~/.zprofile` alone, and a plain non-login `zsh -c` is not required to resolve them (first taken, delegated, as both `~/.zshenv` and `~/.zprofile`; changed under D12) | architect |
| D7 | The one rule and its exceptions; `require-bash.sh` stays as a guard with a host-neutral message | delegated |
| D8 | The environment check is its own SessionStart hook entry | delegated |
| D10 | No harness for this work. The acceptance criteria are test cases written out in this document; the developer runs each one by hand on the hosts it names, at that host's stage, and records the result under it | architect |
| D11 | The check reports what it expected, what it found and the context it ran in, and points at the failed condition's entry in § Troubleshooting a failed condition (now `docs/development-environment.md`, so that nothing the check shows or points at names an issue: the agent's first reply on AC7's run framed the host's environment against this issue); it carries no remedies, and the agent or developer reading it works out the cause on the host from that entry. Amended by the architect 2026-10-23, after AC7: at session start the user is shown a short message naming what is wrong, the likely scenario and the command to run; the pointers go only to the agent, whose context tells it to diagnose the failure in its first reply | architect |
| D12 | The check judges the environment, whatever configured it; setup never overwrites or duplicates the user's shell configuration, and adds a piece only when `--repair` (or the full setup's shell step) finds it missing | architect |
| D13 | Homebrew is a requirement of the macOS development host: `build/macos-setup.sh` stops when it is absent, as today, and never installs it. The case in D12's first wording, setup adding Homebrew's line after installing Homebrew itself, therefore does not arise | architect |
| D14 | AC8's budget: the session-start check finishes within the outstanding-state sweep's time on the same host. The two SessionStart entries run in parallel, so the check then never lengthens session start, and each host is judged against itself rather than against a figure measured on macOS (decided 2026-10-23 from the stage 1 measurement: check 0.29 s, sweep 3.40 s, medians of five) | architect |
| D15 | Condition 7 also judges where NumPy and SciPy load from: each module's file must resolve into the setup's install (on macOS its own formula's Cellar), so a `pip` install shadowing the setup's fails it. Decided 2026-10-23 from a second macOS host, where a `python3` link to Homebrew's Python passed condition 7 while it loaded a pip-installed SciPy 1.17.1 over Homebrew's unlinked 1.18.1 (§ Step 5). Linux and Windows name their place in their stages. Directed by the architect the same day, so the class is detected on every host now rather than when a stage finds it: on every host a module loaded from the user's `site-packages` (where `pip --user` installs), or a module Python sees installed more than once on `sys.path`, fails condition 7 | architect |
| D16 | Condition 3 (and 4, the profiler) also judges where each module loads from, on every host: a module whose file lies outside the Perl's built-in `@INC` (the one it was built with, without what `PERL5LIB` or `PERLLIB` add) and the setup's own directory (on Linux `~/perl5`, D3) fails, as does one with two copies on `@INC` outside the core directories. A dual-life module upgraded over its core copy counts once. Decided by the architect 2026-10-23, extending D15 to Perl | architect |
| D17 | Windows setup sets `BASH_ENV` to `~/.bashrc` as a user environment variable, so the plain Git Bash shell Claude Code runs its hooks in reads the managed block that puts Strawberry Perl first; and the check's session-start message has a Windows story of its own for every failure, rather than falling to the branches written for macOS and Linux. Decided by the architect 2026-10-24, from § Stage 3, the check on this host as found | architect |

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
      Pass when: every condition is reported by number (eleven until D3 as
      settled in stage 2 retired condition 5, ten since), each one
      applicable to the host passes or is a note, those not applicable are
      reported as such, and the exit status is 0. M L W.
      - M, 2026-10-23, pass, on the architect's home after `--repair` (stage
        1 step 5): eleven conditions reported, 9 pass and 2 `n/a` (5, Linux's
        `PERL5LIB`; 11, Windows' line endings), exit 0.
      - M, 2026-10-23, pass, on a second macOS development host, after the
        developer removed a `pip` SciPy and ran the full setup from a
        terminal: 8 pass, 1 note (no `tmux`), 2 `n/a`. That run's condition 8
        context showed a new terminal tab resolving nothing; see § Step 1,
        run from a terminal.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: after `./build/linux-setup.sh --dev-deps --package`, `--validate` reported 1 to 4 and 6 to 11, 8 pass and 2 `n/a` (10, the screenshot tools; 11, Windows' line endings), exit 0.
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
      The run of AC2 on macOS and Windows; on Linux, where the distribution's
      Perl is the development Perl (D3), the modules are hidden from it: a
      stand-in directory holding `Hide.pm`, an `@INC` hook that refuses
      `Devel/Size.pm` and `YAML/PP.pm`, and `PERL5OPT="-I$D -MHide" perl
      process/check-environment.pl`.
      Pass when: condition 3 fails, naming the first module of the host's
      cpanfile that did not load, with its pointer. M L W.
      - M, 2026-10-23, pass (the AC2 run): condition 3 found "Devel::Size does
        not load; 3 of 20 do not: Devel::Size, Text::CSV, Text::CSV_PP", with
        its pointer.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: with `Devel/Size.pm` and `YAML/PP.pm` hidden by the `@INC` hook, condition 3 found "Devel::Size does not load; 2 of 20 do not: Devel::Size, YAML::PP", with its pointer; exit 1.
- [x] **AC3a. A Perl module from outside the setup's install is reported**
      (D16). A copy of a runtime module from the Perl's own `site_perl`, and
      one of a core module, in a stand-in directory put first with
      `PERL5LIB`. Linux: the same, the runtime module's copy taken from the
      distribution's package directory, and a module installed both by the
      distribution and by `cpanm` into a directory on `PERL5LIB`.
      Pass when: condition 3 fails naming each module loading from the
      stand-in, the site copy also as installed twice, the core copy not;
      with no `PERL5LIB`, condition 3 passes. M L W.
      - M, 2026-10-23, pass, on a second macOS development host: Text::CSV
        and Getopt::Long each "loads from <D>/…, outside this Perl's install
        and the setup's"; "Text::CSV is installed 2 times", with both paths;
        Getopt::Long not counted twice; without `PERL5LIB` both conditions 3
        and 4 pass. The system Perl run (AC2) reads as before D16: Apple's
        `/System/Library/Perl/Extras` is on that Perl's built-in `@INC`.
        The full check took 0.35 s before and after (medians of five).
      - L, 2026-10-23, Ubuntu 26.04.1, pass: copies of Text::CSV (from `/usr/share/perl5`) and Getopt::Long (core, from `perl-base`) in a stand-in directory on `PERL5LIB`: each "loads from <D>/…, outside this Perl's own install"; "Text::CSV is installed 2 times: <D>/Text/CSV.pm, /usr/share/perl5/Text/CSV.pm"; Getopt::Long not counted twice. Without `PERL5LIB` conditions 3 and 4 pass. The copy stands in for a `cpanm` install, as `cpanm` is not on this host; Debian's `perl-base` counted as core, as D16 read it.
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
- [x] **AC4a. NumPy or SciPy from outside the setup's install is reported**
      (D15). macOS, on a host whose Homebrew Python has a module installed
      with `pip` in its `site-packages`: `ln -s <Homebrew python3.x>
      "$D/python3"; PATH="$D:$PATH" perl process/check-environment.pl
      --condition 7`, then the same with `PYTHONPATH` set to the formula's
      own `site-packages` in its Cellar. Linux and Windows: the same, with
      the module installed by `pip install --user` over the setup's, then
      with it removed. Each host also runs the table's other Python forms
      (§ Phase 4: investigation stages, the scenarios). Pass when: the first
      run fails condition 7 naming the file the module loads from, with its
      pointer; the second passes. M L W.
      - M, 2026-10-23, pass, on a second macOS development host (§ Step 5,
        the second host): the first run failed, found `<D>/python3 ->
        …/Cellar/python@3.14/…/python3.14; SciPy loads from
        /opt/homebrew/lib/python3.14/site-packages/scipy/__init__.py`; with
        `PYTHONPATH=/opt/homebrew/Cellar/scipy/1.18.1_1/lib/python3.14/site-packages`
        it passed. The code before D15 passed the first run. The host as it
        stands reads as before, condition 7 naming `/usr/bin/python3`; the
        full check took 0.16 s before and after (medians of five).
      - M, 2026-10-23, pass, the tests every host runs, on the same host with
        stand-ins: a copy of Homebrew's NumPy in a scratch user
        `site-packages` (`PYTHONUSERBASE`) failed, "NumPy loads from the
        user's site-packages, …" and "NumPy is installed 2 times"; a
        `python3` link to Homebrew's 3.14 failed with "NumPy is installed 2
        times: 2.4.6 in …/numpy-2.4.6.dist-info, 2.5.4 in
        …/numpy-2.5.4.dist-info" and SciPy outside its Cellar; Python 3.15
        with Homebrew's SciPy on `PYTHONPATH` passed. The full check took
        0.35 s against 0.29 s before (medians of five, this host now
        starting Homebrew's Python 3.15), inside D14's budget.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: a copy of the distribution's NumPy in a scratch user `site-packages` (`PYTHONUSERBASE`) failed condition 7, "NumPy loads from the user's site-packages, …" and "NumPy is installed 2 times: 2.3.5 in <user>/numpy-2.3.5.dist-info, 2.3.5 in /usr/lib/python3/dist-packages/numpy-2.3.5.dist-info"; without it, pass. The other forms: a venv's `python3` first, without the modules, failed "NumPy or SciPy does not import"; a venv with `--system-site-packages` first passed, as it loads the distribution's modules from their place (the place test judges where the modules load from; the interpreter's path resolves to `/usr/bin/python3.14`).
- [ ] **AC5. The check writes nothing.** `T=$(mktemp -d)`, then, a second
      later, `M=$(mktemp)`; then `HOME="$T" ZDOTDIR="$T" perl
      process/check-environment.pl`, then `find "$T" -newer "$M"` and
      `git status --porcelain`. Then `find . -maxdepth 1 -newer "$M"` in the directory the check ran
      from, which `git status` does not see for an ignored file. The mark is made outside the throwaway home
      and after it: made inside it, it leaves the home's directory a few
      microseconds newer than itself, and `find` lists the home on every run
      (measured on macOS, three runs without the check, 2026-10-23).
      Pass when: `find` lists nothing and `git status` is as it was before
      the run. M L W.
      - M, 2026-10-23, on a second macOS development host: the check left
        `nytprof.out` in the directory it ran from whenever the profiler is
        installed; see § Step 1, the profiler started by condition 4. After the
        fix, the full check with Homebrew's Perl first: both `find` runs
        listed nothing.
      - M, 2026-10-23, pass: `find` listed nothing, `git status` unchanged.
      - M, 2026-10-23, pass, on a second macOS development host after D15 and
        D16 (Python and Perl started to judge where each module loads from):
        `find` listed nothing, `git status` unchanged.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: `find` in the throwaway home and in the checkout listed nothing; `git status` unchanged by the run.

**The session-start check (R3)**

- [ ] **AC6. No Perl on `PATH`.** Link into a stand-in directory only `sh`
      and the commands the hook's launcher calls, then run the hook's command
      as `settings.json` holds it: `env -i PATH="$D" sh -c '<command>'`.
      Pass when: it prints that no Perl was found, the `PATH` it saw and the
      pointer to condition 1's entry, and exits so that the session proceeds.
      M L W.
      - M, 2026-10-23, pass: with only `sh` (macOS's, which is `/bin/bash`)
        linked into the stand-in directory, the command read from
        `.claude/settings.json` printed valid SessionStart JSON: a
        `systemMessage` naming condition 1 with its pointer, and an
        `additionalContext` saying no `perl` was on `PATH`, the `PATH` it saw
        and the pointer; exit 0, nothing on stderr.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: with only `sh` linked into the stand-in directory, the command from `.claude/settings.json` printed the SessionStart JSON naming condition 1 with its pointer and the `PATH` it saw; exit 0.
- [ ] **AC7. A session started on a wrong environment.** From the checkout,
      start Claude Code as `PATH="/usr/bin:/bin:$PATH" claude` (on Windows,
      Git's `/usr/bin` first from Git Bash).
      Pass when: the user sees what is wrong, the likely scenario (Claude
      Code started with a `PATH` that differs from a new terminal's) and the
      step that fixes it; and the agent's first reply, to whatever the user
      sends, reads the entries the pointers name and reports the `PATH` order
      as the cause. M L W.
      - M, 2026-10-23, on a second macOS development host, the session
        started by the architect on a broken `PATH` (Homebrew's `bin` after
        `/usr/bin` and `/bin`, no Perl keg): the hook's report reached the
        agent's context, 3 pass, 4 FAIL (2 `/usr/bin/perl` 5.34.1; 3 the
        three modules that Perl lacks; 6 `/bin/bash` 3.2; 7 `/usr/bin/python3`),
        each with its pointer. From entries 2, 6 and 7 and the entry's first
        note (the check sees the environment of whatever started it), the
        agent named the cause: the `PATH` Claude Code inherited puts the
        system directories ahead of Homebrew's, while condition 8 shows a
        clean login shell resolving Homebrew's three tools, so the shell
        files are right and the fault lies in how the session was started.
        What the user saw is the architect's to confirm.
      - M, 2026-10-23, fail, rerun by the architect from a new session on the
        broken `PATH`, after D11's amendment: the user saw the message naming
        the three system tools, the scenario (Claude Code started with a
        `PATH` that differs from a new terminal's) and the fix; the agent's
        first reply, to "hi", found the cause (`/usr/bin:/bin` put in front in
        the terminal tab before `claude` ran, condition 8 passing) and the
        fix, but opened by saying the failure was not caused by this issue's
        work, framing a host's environment against an issue. The pointers led
        into this issue's document, and `CLAUDE.md` asks every reply to say
        whether a problem was caused by the work in progress. The entries
        moved to `docs/development-environment.md`; the agent's instruction
        and the `CLAUDE.md` session-start item now say a failed check is the
        host's, never related to an issue or branch; the check's output
        carries no issue reference. To be rerun.
      - M, 2026-10-23, pass, rerun by the architect from a new session on the
        broken `PATH`: the user saw the message; the agent's first reply
        opened with the verdict that the failures come from the machine's
        setup, not the repository, named no issue or branch, tabled what the
        session and a clean login shell resolve for conditions 2, 3, 6 and 7,
        named the cause (the tab's `PATH` changed by hand, `/usr/bin:/bin` in
        front, condition 8 passing) and the fix (a new terminal tab, nothing to
        install, no `--repair`).
      - L, 2026-10-23, Ubuntu 26.04.1, pass, the session started by the
        architect as `PATH="/tmp/ltl-ac7/bin:$PATH" claude`, the stand-in
        directory holding a copy of `/usr/bin/perl`: the user saw "this
        session finds perl /tmp/ltl-ac7/bin/perl (v5.40.1)", the scenario
        (Claude Code started with a `PATH` that differs from a new
        terminal's) and the fix; the check reported condition 2 failing, the
        other seven applicable passing. The agent's first reply, to "hi",
        read condition 2's entry, named the cause (the directory put in front
        of `PATH` by hand in the shell that started `claude`, no shell file
        adding it, condition 8 resolving `/usr/bin/perl` in every mode) and
        the fix (a new terminal), and named no issue or branch.
- [ ] **AC8. The hook is fast enough to run at every session start.** On a
      set-up host, `time sh -c '<command>'`, five runs.
      Pass when: the median is within the median of five timed runs of the
      outstanding-state sweep (`process/claude-hooks/session-start.sh`) on the
      same host (D14). M L W.
      - M, 2026-10-23, pass: the hook's command, five runs, 0.28 to
        0.30 s, median 0.29 s. Each condition alone (`--condition N`, five
        runs, medians): startup and condition 1 0.02 s; condition 3, the
        twenty runtime modules, 0.07 s; condition 7, the NumPy and SciPy
        import, 0.11 s; condition 8, three clean zsh starts, the `-lic` one
        reading the architect's `~/.zshrc`, 0.10 s; the others 0.02 to
        0.03 s. The outstanding-state sweep of
        `process/claude-hooks/session-start.sh`, the other SessionStart
        entry, five runs: 3.27 to 4.06 s, median 3.40 s. The two run in
        parallel (§ How Claude Code runs a hook), so the check adds nothing to
        how long a session takes to start on this host.
      - M, 2026-10-23, pass, on a second macOS development host after D15 and
        D16, `CLAUDE_PROJECT_DIR` set to the checkout: the hook's command,
        five runs, 0.35 to 0.37 s, median 0.36 s; the outstanding-state
        sweep, five runs, median 4.28 s.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: the hook's command, five runs, 0.40 to 0.41 s, median 0.40 s; the outstanding-state sweep, five runs, 2.05 to 2.43 s, median 2.23 s.

**Setup (R4, R5)**

- [ ] **AC9. `--repair` and `--validate` install nothing.** In a stand-in
      directory, put a script for each of `brew`, `cpanm`, `apt-get` and
      `winget` that appends its name and arguments to `$D/calls`; the `brew`
      one also passes `--prefix` and `shellenv` on to the real `brew`. Run
      `HOME="$T" ZDOTDIR="$T" PATH="$D:$PATH" <setup> --validate`, then the
      same with `--repair`.
      Pass when: `$D/calls` holds no line other than `brew --prefix` and
      `brew shellenv`. M L W.
      - M, 2026-10-23, pass, in an empty throwaway home: after `--validate`
        `$D/calls` was empty (exit 1, condition 8 failing in the empty home);
        after `--repair` it held `brew --prefix` alone (exit 0).
      - L, 2026-10-23, Ubuntu 26.04.1, pass: stand-ins for `apt-get`, `apt`, `sudo`, `cpanm`, `brew`, `winget`, `pip` and `pip3`; after `--validate` and `--repair` (both exit 0) `$D/calls` was empty.
- [ ] **AC10. `--repair` adds nothing to a configuration that already works.**
      Seed the throwaway home's shell files with the line `export KEEP=1` and
      the host's own configuration of its tools, as a developer who already
      uses them carries it (macOS: Homebrew's `eval "$(<prefix>/bin/brew
      shellenv)"` in `.zprofile`; Linux: nothing, since the distribution's
      tools are on its default `PATH` (D3), so `.profile`, `.bash_profile`
      and `.bashrc` hold `export KEEP=1` alone; Windows: what stage 3
      establishes), copy the files aside, run `HOME="$T" ZDOTDIR="$T" <setup>
      --repair`, `cmp` each file with its copy.
      Pass when: the check passes and `cmp` reports no difference. M L W.
      - M, 2026-10-23, pass: `.zshenv`, `.zprofile` and `.zshrc` each seeded
        with `export KEEP=1`, `.zprofile` also with Homebrew's line; the shell
        step reported "Nothing to add", the check passed (exit 0), `cmp`
        reported no difference in any of the three.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: `.profile`, `.bash_profile` and `.bashrc` each `export KEEP=1`; `--repair` reported "Yes. Nothing to add.", the check passed (exit 0), `cmp` found no difference.
- [ ] **AC10a. `--repair` adds exactly the missing piece, once.** Seed the
      throwaway home's shell files with `export KEEP=1` only. Run `HOME="$T"
      ZDOTDIR="$T" <setup> --repair`, copy the files aside, run it again, `cmp`
      each file with its copy.
      Pass when: after the first run each file still holds `export KEEP=1`
      unchanged, the check passes, and the only addition is one delimited
      piece for what the check reported missing (on Linux none: nothing is
      missing, D3); after the second run `cmp` reports no difference. M L W.
      - M, 2026-10-23, pass: the first run left `.zshenv` and `.zshrc` as
        `export KEEP=1` alone and appended to `.zprofile` one block, `# >>>
        ltl homebrew >>>`, `eval "$(/opt/homebrew/bin/brew shellenv)"`,
        `# <<< ltl homebrew <<<`; the check passed (exit 0). The second run
        reported "Nothing to add" and `cmp` found no difference.
      - L, 2026-10-23, Ubuntu 26.04.1, pass, the same run (D3: nothing is missing on Linux): nothing added; a second `--repair` exit 0, `cmp` found no difference in any of the three files.
- [x] **AC10b. Setup links what it installs, and leaves files it did not put
      there.** macOS, on a host with a formula installed but not linked
      because a `pip` install holds its paths: `./build/macos-setup.sh`.
      Linux and Windows: each host's full setup with a `pip install --user`
      copy of NumPy or SciPy in place, and with Python's or Perl's modules
      left on an earlier minor version (the scenarios' table). Pass when: it
      exits 1 naming each colliding directory with its file count and the
      pointer, every formula already linked is left as it is, and `find`
      lists nothing newer than a mark made before the run in the Python
      `site-packages` directories; on Linux and Windows, setup either brings
      the setup's copy into effect without removing the developer's files,
      or stops naming them, and the check passes only in the first case.
      M L W.
      - M, 2026-10-23, pass, on a second macOS development host (§ Step 5,
        the second host): exit 1, "scipy is installed but cannot link",
        `1289 /opt/homebrew/lib/python3.14/site-packages/scipy` (the count
        `brew link --overwrite --dry-run` gives); perl, bash, python, numpy
        and cpanminus already linked, untouched; `find` listed nothing. The
        developer then removed pip's SciPy (`pip uninstall`) and ran the full
        setup: "[link] Linking scipy", Homebrew reporting 2854 symlinks
        created, and the check passing condition 7 on Python 3.15.
      - L, 2026-10-23, Ubuntu 26.04.1, pass, the stop case: the full setup with a copy of NumPy in a scratch user `site-packages` exited 1, condition 7 naming the user copy's file; the shell step added nothing; `find` listed nothing newer than the mark in either `site-packages`. Its message first read "a line in the shell configuration puts other tools first", wrong for this cause; it now says the report and its troubleshooting entry show where the cause lies.
- [ ] **AC11. Every login shell resolves the same tools.** After AC10a's first
      run, for each login mode `-lc` and `-lic`:
      `env -i HOME="$T" ZDOTDIR="$T" zsh <mode> 'command -v perl bash python3'`
      (bash on Linux; on Windows the Git Bash modes stage 3 establishes).
      Pass when: each login mode prints the paths conditions 2, 6 and 7
      expect, and AC10a added nothing to `.zshenv`. M L W.
      - M, 2026-10-23, pass: `-lc` and `-lic` each printed
        `/opt/homebrew/bin/perl`, `/opt/homebrew/bin/bash`,
        `/opt/homebrew/bin/python3`, links into Homebrew's Cellar; `.zshenv`
        still `export KEEP=1` alone.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: after AC10a's run, `env -i HOME="$T" bash -lc` and `-lic` each printed `/usr/bin/perl /usr/bin/bash /usr/bin/python3`.
- [ ] **AC12. The Linux setup installs every module from the
      distribution's packages** (D3, settled in stage 2; first written for
      `local::lib`, modules under `~/perl5`). On a Debian or Ubuntu host, run
      `./build/linux-setup.sh --dev-deps`, then `--validate`, then load each
      cpanfile module and print the file it loads from.
      Pass when: `--validate` exits 0; every module loads from the Perl's
      built-in `@INC`, none from `~/perl5`; `PERL5LIB` is unset; no `cpanm`
      ran. L.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: after `--dev-deps`, `--validate` exit 0; `PERL5LIB` unset; no `~/perl5`; no `cpanm` on the host. Every module loads from the Perl's built-in `@INC`: the cpanfile's from `/usr/share/perl5` and `/usr/lib/x86_64-linux-gnu/perl5/5.40`, the core ones from `perl-base`, `/usr/share/perl/5.40` and `/usr/lib/x86_64-linux-gnu/perl/5.40`.

**The rule (R6, R7, R9)**

- [x] **AC13. No interpreter named by location.** `git grep -nE 'brew
      --prefix|/opt/homebrew|^#!/usr/bin/perl|^#!/bin/bash|(^|[;[:space:]])(export
      +)?PATH=' -- ltl '*.sh' '*.pl' '*.py' build process prototype tests`.
      Pass when: every line it prints is in one of the exceptions or the
      historical records named in § Phase 4: the one rule every script
      follows. M.
      - M, 2026-10-23, pass, at stage 1 step 4: 26 lines, every one in the
        setup scripts (`build/macos-setup.sh`, `build/windows-setup.ps1`), the
        container builds (`build/ubuntu-package.sh`, `build/windows-package.sh`,
        `prototype/720-packed-generated-loop/pack-windows.sh`), the screenshot
        test's own fixture (`tests/validate-screenshot-capture.sh`), or the
        historical records (`build/packaging-notes`, three prototype reports,
        `tests/profile/results/`).
- [ ] **AC14. No message about Homebrew where there is none.** On Linux, run
      `prototype/412-notice-surfaces/check-tmux.sh`,
      `prototype/412-notice-surfaces/capture/specimens.sh` and every harness
      as AC16 starts it on Linux, capturing stderr; `grep -i brew` the
      captures.
      Pass when: `grep` finds nothing. L.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: `prototype/412-notice-surfaces/check-tmux.sh` (scenario `modal-quit`, exit 0) and `capture/specimens.sh` (every case its expected result, against the two known-bad trees taken with `git archive`) each printed nothing matching `brew`; nor did the 53 harnesses started with `--list` (AC16's Linux run).
- [ ] **AC15. `ltl` starts through `env perl`.** `./ltl --version`, and on
      Windows `ls /opt/homebrew/bin/perl`.
      Pass when: `ltl` prints its version on every host, and on Windows `ls`
      reports no such file. M L W.
      - M, 2026-10-23, pass: first line `#!/usr/bin/env perl`; `./ltl
        --disable-progress --version` printed `0.20.0-750`.
      - L, 2026-10-23, Ubuntu 26.04.1, pass: `./ltl --disable-progress --version` printed `0.20.0-750`, first line `#!/usr/bin/env perl`.
- [ ] **AC16. The harness suite passes, and every harness starts on each
      host it runs on.** macOS: the completion gate's full suite
      (`docs/process/workflow.md` § 3), run once, after stage 4; pass when
      every harness passes. Linux: what this work changes there is how a
      harness finds bash, Perl and Python, so each `tests/validate-*.sh` is
      started with `--list` under the Linux setup; pass when each starts
      (lists its scenarios, or stops at its own check for a corpus file, past
      the interpreter guard) and none prints anything matching `brew`. No
      stage runs the full suite; on the Linux host the `logs/` corpus is not
      available. M L. (First written as the full suite on both hosts, which
      contradicts `CLAUDE.md`'s rule that the full suite runs once, as the
      completion gate; corrected by the architect in stage 2.)
      - L, 2026-10-23, Ubuntu 26.04.1, pass: 53 harnesses started; 41 listed
        their scenarios, 12 stopped at their own "not found" check for a
        corpus file; `grep -i brew` found nothing.

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
      - M, 2026-10-23, pass, on a second macOS development host: with the
        cpanfile's develop block requiring `Devel::NYTProf` and the profiler
        loading in Homebrew Perl 5.44.0 (condition 4 passing),
        `build/macos-package.sh arm64` from a clean login shell; `unzip -l`
        lists 148 entries, none naming `Devel/NYTProf`. C (the CI builds)
        is stage 4's.

**The records (R10)**

- [ ] **AC20. The instructions name the setup, not a `PATH` line.**
      `git grep -n 'brew --prefix\|opt/homebrew' -- README.md CLAUDE.md
      docs/toolchain-guidance.md`, then read each host's setup instructions.
      Pass when: `git grep` finds nothing, and each host's instructions name
      its setup with `--repair` and `--validate`. M.
      - M, 2026-10-23, partial, at stage 1 step 4: the search finds nothing in
        `README.md` or `CLAUDE.md`, and the macOS instructions name
        `build/macos-setup.sh` with `--validate` and `--repair`. It still finds
        `docs/toolchain-guidance.md` § Windows development host, trap 3 (the
        shim), which stage 3 rewrites; the Linux and Windows instructions are
        stages 2 and 3's.

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
  expected and found lines and `see: docs/development-environment.md
  § Troubleshooting a failed condition, <n>`; a last line counting each
  result. Exit 0 with no `FAIL`, 1 with any, 2 on a usage error.
- **Options:** `--hook` prints the SessionStart JSON
  (`hookSpecificOutput.additionalContext` carries the whole report, preceded,
  when a condition fails, by an instruction to the agent to diagnose it in its
  first reply; a `systemMessage`, shown to the user, names what is wrong, the
  likely scenario and the command to run (D11 as amended), and is absent
  when nothing fails) and exits 0; `--condition N[,N...]` runs only those
  conditions, for the profiling preflight (step 4); `-h`, `--help`. An unknown
  option prints usage to stderr and exits 2 having tested nothing.
- **Proven by** AC2 (the wrong Perl first), AC3 (a Perl without the modules),
  AC4 (old bash; the system Python), AC5 (writes nothing). AC1 waits for
  step 3's `--validate`.
- **Run from a terminal** (found on a second macOS host, 2026-10-23): the
  developer's full setup, run in a terminal, reported condition 8's new
  terminal tab (`zsh -lic`) resolving no `perl`, `bash` or `python3`, where
  every run from the agent's shell had resolved them. Reproduced under a
  pseudo-terminal (`script -q`): the full check took 20.31 s against 0.32 s
  without one. Each tool was started in a process group of its own, still
  attached to the terminal; the interactive zsh, touching the terminal from
  a background group, was stopped until the 20-second timeout killed it.
  `run_capture` now starts each tool in a session of its own (`setsid`),
  which has no controlling terminal and still lets a timeout kill the whole
  group. After the change, under the pseudo-terminal: 0.37 to 0.38 s, the tab
  line resolving all three tools, 8 pass; without one, 0.37 s and the same
  result; the hook's output unchanged. Only `-lic` touches the terminal, so
  only that context line, never a condition's result, was affected.
- **The profiler started by condition 4** (found on a second macOS host,
  2026-10-23): the session-start sweep reported a `nytprof.out` in the
  repository root, 487 bytes, its header naming `-e` under Perl 5.44.0.
  Loading `Devel::NYTProf` starts the profiler, which writes `nytprof.out`
  into the current directory: from a scratch directory, with Homebrew's Perl
  first, `--condition 3` left nothing and `--condition 4` left the file. The
  session-start hook runs from the repository root, so every session on a
  host with the profiler installed left one there. AC5 had not caught it:
  `nytprof.out` is ignored by git, and its `find` looked only in the
  throwaway home. The module test now runs with `NYTPROF=start=no`, which
  loads the profiler without starting it; the full check then left the
  directory empty. AC5 now also looks in the directory the check ran from.

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
- **The link step** (full setup, after the installs): `brew install` leaves
  a formula that is installed but not linked as it is ("already installed,
  it's just not linked"), so each formula setup installs is linked. A formula
  whose files collide with files put there another way (a `pip` install)
  is not linked: setup names the colliding directories with their file
  counts, leaves them (D12), points at troubleshooting entry 7 and exits 1.
  The collisions are found from the formula's Cellar files and
  `brew info --json=v2` (`linked_keg`), never by asking `brew link`.
  Measured on a second macOS host, 2026-10-23, Homebrew 7.0.10: a `brew link`
  that fails on a collision removes its links but leaves the directories it
  made, and `brew link --overwrite --dry-run` makes them too; the empty
  `python3.15/site-packages/scipy` then imports in Python 3.15 as an empty
  namespace package with no `__version__`. The 148 empty directories these
  runs left were removed, by birth time and `rmdir`.
- **The shell step** (`--repair`, and the full setup's; D12, D6): run the
  check; when condition 8 passes, add nothing. When it fails, ask a clean
  login shell (`env -i … /bin/zsh -lc`) for `HOMEBREW_PREFIX`, which
  Homebrew's own line (`brew shellenv`) exports: when it is unset, Homebrew's
  line is the missing piece, and it is appended once to
  `${ZDOTDIR:-$HOME}/.zprofile` between the markers the Windows setup already
  uses (`# >>> ltl homebrew >>>`, `# <<< ltl homebrew <<<`), as
  `eval "$(<prefix>/bin/brew shellenv)"` with the prefix written out. If the
  markers are already there, or a login shell already has `HOMEBREW_PREFIX`,
  nothing is added: the cause lies in a line the user owns, and the check's
  report shows it. Then run the check again.
- **Why `HOMEBREW_PREFIX`, measured on macOS, 2026-10-23:** the rule first
  written here took Homebrew's line as missing when `$(brew --prefix)/bin` was
  absent from a clean login shell's `PATH`. On this host that rule adds
  nothing: `/etc/paths.d/homebrew` holds `/opt/homebrew/bin`, so `path_helper`
  puts it on every clean login shell's `PATH`, behind `/usr/bin`, while
  condition 8 fails. A clean login shell here has no `HOMEBREW_PREFIX`;
  `brew shellenv` (Homebrew 7.0.10) exports it along with `PATH`. The
  variable tells whether Homebrew's own line ran, whoever wrote it, where
  `PATH` cannot.
- **Paths no criterion reaches, run on macOS, 2026-10-23:** `.zprofile`
  holding the block followed by `export PATH=/usr/bin:/bin:$PATH`, and
  holding Homebrew's line followed by the same: nothing added, the file
  unchanged, the check's report showing the cause, exit 1. A `.zprofile`
  without a final newline: the block added on lines of its own.
- **The Perl keg line:** with PAR::Packer installed for Homebrew Perl (this
  host has none for 5.44; asked of the architect before installing), build the
  binary from a clean login shell carrying only Homebrew's line
  (`build/macos-package.sh arm64`, which runs `perl -S pp`), and see which
  `pp` it starts and whether the binary runs. The keg line becomes a second
  piece of the shell step only if this shows it is needed.
  Attempted 2026-10-23, with the architect's go-ahead: `perl -S cpanm
  --notest PAR::Packer` under Homebrew Perl 5.44 installed nothing. The
  network's web proxy answered the `Archive-Zip-1.68.tar.gz` download with an
  HTML block page ("Not allowed to upload/download encrypted or
  password-protected archive files"), so `Archive::Zip`, then `PAR`, then
  PAR::Packer bailed out. Read, not measured: `/usr/bin/pp`, which `perl -S`
  finds without the keg line, is the four lines `use strict; use warnings;
  use pp; pp->go();`, so under Homebrew Perl it would load Homebrew Perl's own
  `pp.pm`. **Parked by the architect (2026-10-23), to be done from another
  host**, not behind this network's proxy: this measurement, and with it
  AC19's macOS build, which needs PAR::Packer on the host as well.
  **Measured on a second macOS development host, 2026-10-23: the keg line is
  not needed.** That host has Homebrew Perl 5.44.0 with PAR::Packer 1.064
  installed, and a `~/.zprofile` holding Homebrew's own line only. From
  `env -i HOME=… USER=… TERM=… /bin/zsh -lc`: `HOMEBREW_PREFIX=/opt/homebrew`,
  `perl` resolves `/opt/homebrew/bin/perl` (5.44.0); the keg's `bin`, which
  holds Homebrew Perl's own `pp`, is not on `PATH`, so `perl -S pp` finds
  macOS's `/usr/bin/pp`, whose `use pp;` under Homebrew Perl loads
  `/opt/homebrew/opt/perl/lib/perl5/site_perl/5.44/pp.pm` and PAR::Packer from
  the same `site_perl`. `build/macos-package.sh arm64` built the binary
  (Mach-O arm64, linked against `libSystem` alone, its archive's modules from
  `5.44.0/darwin-thread-multi-2level`), which ran `--version` with exit 0 and
  passed the read-path check. The shell step stays Homebrew's line only.
- **CI:** `.github/workflows/release-build.yml` runs
  `./build/macos-setup.sh --package`. Verified by a manual run of that
  workflow on the issue branch (its release job runs on tags only), asked of
  the architect first.
  Run 2026-10-23 (run 40015452666, at `de4d789c`): success; build-macos,
  build-ubuntu amd64 and arm64 and build-windows passed, release skipped. On
  GitHub's macOS runner the shell step found condition 8 failing (a clean
  login shell resolved `/usr/bin/perl` 5.34.1, `/bin/bash` 3.2 and the
  python.org `python3` in `/Library/Frameworks`), added Homebrew's line to
  the runner's `~/.zprofile`, and the final check read 7 pass, 0 FAIL, notes
  for the profiler and `tmux`; condition 7 passed under D15's tests on
  every host, with the python.org Python also present. The link step
  printed nothing: every formula was already linked.
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
- `tests/lib/require-bash.sh`: the remedy line points at the environment
  check, `perl process/check-environment.pl`, the same on every host; its
  header comment rewritten the same way. First planned as the host's setup
  chosen by `uname -s`; changed while building it, because `--validate` runs
  exactly that check, the line is right on every host now and after stages
  2 and 3 without another edit, and the check's report already points at the
  troubleshooting entries that name the setup's modes. The Python hints
  (§ Phase 4: the one rule every script follows) carry the same line, and a
  second one naming `README.md` § Test-harness dependencies for the install
  steps per host.
- `tests/validate-section-layout.sh` tested that every input exists with
  `[[ -e "$f" ]]`, `$PERL` among them, which a bare `perl` fails: `$PERL` left
  that list for a `command -v` test of its own.
- `tests/profile/profiling-preflight.sh`: its check 1, a second test for
  "not the system Perl" that names `/usr/bin` and so would fail on Linux,
  where `/usr/bin/perl` is the expected Perl, becomes a call of
  `process/check-environment.pl --condition 1,2`, keeping its exit code 1; on
  a failure it prints that report, whose pointers name the troubleshooting
  entries. With no `perl` at all, where the check cannot run, it prints
  condition 1's pointer itself. Its remedy for a missing `cpanm` names
  `./build/macos-setup.sh --dev-deps` on macOS and nothing elsewhere, until
  stages 2 and 3 give those hosts a setup. Its one consumer,
  `tests/profile/run-profile.sh`, reads only the exit code.
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
- **Run on macOS, 2026-10-23:** `perl -c`, `bash -n` and `py_compile` clean on
  every changed script. `tests/validate-value-display.sh --scenario
  zero-duration` and `tests/validate-section-layout.sh --scenario
  layout-baseline` under `bash -x`, before and after: both pass both times;
  before, `PERL=/opt/homebrew/bin/perl`; after, `PERL=perl`, each check script
  started as `perl <script>`. Each rewritten message made to fire: a harness
  under `/bin/bash` (exit 2, pointing at the check); a `python3` that cannot
  import NumPy first on `PATH` (`tests/validate-statistics.sh`,
  `tests/validate-distribution-shape.sh`), no `python3` on `PATH`
  (`tests/validate-profile.sh`), and the anchor generator under a Python
  without NumPy, each exit 1 with the two lines; the profiling preflight on
  this host (exit 0) and with the system Perl first (exit 1, the check's
  report for conditions 1 and 2). `tests/baseline/compare-results.sh summary`
  on two released TSVs under `/bin/bash` and under the new first line: the
  same 347 lines. `build/generate-cpanfile.sh` under both: the same output,
  the tracked cpanfiles unchanged. The benchmark records `ltl`'s own timings
  (`-V benchmark-data`), so the runner's bash does not enter the before and
  after comparison.
- Found on the way, fixed in step 1's script: started by the bare name
  `perl`, macOS's system Perl gives `$^X` as `perl`, and the header read "ran
  under perl"; the header now finds the name on `PATH`, as the shell did.

### Step 5: this host

- `build/macos-setup.sh --validate` on the architect's own home: condition 8
  is expected to fail (§ Phase 4: what Homebrew's own configuration already
  provides on macOS). Moving the `~/.zshrc` lines, or running `--repair`, is
  the architect's choice; then AC1.
- AC7, a session started on a wrong `PATH`, is run by the architect.
- **Run on the architect's home, 2026-10-23.** `--validate` before: 8 pass,
  condition 8 failing as expected (a clean login shell resolved
  `/usr/bin/perl`, `/bin/bash` 3.2 and `/usr/bin/python3`; a new tab resolved
  Homebrew's), with Homebrew's lines in `~/.zshrc` alone and no `~/.zprofile`.
  The architect chose `--repair`, over moving the `~/.zshrc` lines by hand,
  knowing a new tab then runs `brew shellenv` twice. `--repair` created
  `~/.zprofile` holding the one marked block and left `~/.zshrc` and
  `~/.zshenv` byte for byte as they were; condition 8 then passed. A second
  `--repair` reported "Nothing to add" and left `~/.zprofile` unchanged. A
  clean `zsh -lc` resolved `/opt/homebrew/bin/perl`, `bash` and `python3`, a
  clean `zsh -lic` the same with the keg's `perl`. The session-start hook's
  command printed no `systemMessage`.
- Found there: the block was written after a blank line even into a new,
  empty `~/.zprofile`. The separator is now written only when the file
  already holds something; checked in throwaway homes with `.zprofile`
  absent, ending in a newline, and ending without one.
- **Run on a second macOS development host, 2026-10-23**, whose Python was
  set up by hand rather than by `build/macos-setup.sh`. `--validate`: exit 1,
  6 pass, conditions 7 and 8 failing; conditions 1 to 6 pass. What the host
  holds, read from Homebrew and the site-packages directories:
  - Homebrew's Python is `python@3.14` alone, installed as another formula's
    dependency. It links only versioned names (`python3.14`); there is no
    unversioned `python3` link, so `/usr/bin/python3` (no NumPy) comes first.
    Homebrew's `python` alias, which the full setup installs, now names
    `python@3.15`, which is not installed.
  - NumPy 2.4.6 and SciPy 1.17.1 were installed with `pip` into Homebrew
    Python 3.14's `site-packages`; Homebrew's NumPy 2.5.4 and SciPy 1.18.1
    were installed later. NumPy 2.5.4 is linked over pip's files, while pip
    still lists 2.4.6. Homebrew's SciPy 1.18.1 is not linked
    (`brew link --dry-run scipy` would link it), so Python 3.14 imports pip's
    SciPy 1.17.1. Homebrew's NumPy is also linked into
    `lib/python3.15/site-packages`, for a Python that is not installed.
  - What the check reports: condition 7 names `/usr/bin/python3`, and
    condition 8 shows every shell mode resolving it; the shell files are not
    the cause here, while troubleshooting entry 8 points at them. With a
    `python3` link to Homebrew's 3.14 put first on `PATH` (a scratch
    directory, the host unchanged), condition 7 passes: it tests that
    `import numpy, scipy` succeeds, not which install each comes from.
    Resolving each module's file tells the installs apart: NumPy's
    `__init__.py` resolves into `Cellar/numpy/2.5.4`, SciPy's stays in
    `lib/python3.14/site-packages`.

### Not in stage 1

The full harness suite runs once, at the completion gate after stage 4, on
this host; AC16's macOS result is recorded there. Linux setup, the Windows
setup's options and modes, the shim's removal, and the container builds
belong to stages 2 to 4.

## Stage 2: the Linux development host

### The check on this host, as found (2026-10-23)

Ubuntu 26.04.1 LTS, the distribution's Perl 5.40.1 at `/usr/bin/perl`, bash
at `/usr/bin/bash`, Python 3.14 at `/usr/bin/python3`; `PATH` the
distribution's default with `~/.local/bin` first. `perl
process/check-environment.pl` took 0.46 s and exited 1: 4 pass, 4 FAIL, 1
note, 2 n/a.

| # | Result | Found |
|---|---|---|
| 1, 2, 6, 9 | pass | `perl`, `bash` (4 or later) and `tmux` on `PATH`, the distribution's |
| 3 | FAIL | 7 of 20 runtime modules do not load: Devel::Size, Text::CSV, Text::CSV_PP, YAML::PP and its three schema modules |
| 4 | note | Devel::NYTProf does not load |
| 5 | FAIL | `PERL5LIB` not set; no `~/perl5` |
| 7 | FAIL | `/usr/bin/python3` imports neither NumPy nor SciPy |
| 8 | FAIL | every shell mode (`-lc`, `-lic`, `-c`) resolves the same three tools as the check's own `PATH`; fails on condition 7's Python only |
| 10 | n/a | not expected on Linux: the screenshot tool draws its PNG with WebKit on macOS (`features/598-screenshot-capture.md` D23) |
| 11 | n/a | Windows only, by the conditions table |

Nothing of ltl's is installed on this host: no `~/perl5`, no `local::lib`, no
`cpanm`, no `lib*-perl` package for the cpanfile's modules, no NumPy or SciPy,
and no `logs/` corpus in the checkout. `perl -c ltl` fails at its first
non-core `use` (Devel::Size). The report matches the host: each FAIL names a
piece that is absent, and the three tools resolve the same in every shell
mode. The host is a clean start for the Linux setup script that stage 2
writes.

### `build/linux-setup.sh` (D3: the distribution's packages)

Debian and Ubuntu; stops without `apt-get`. The option set of D9 (`--dev-deps`,
`--package`, `--repair`, `--validate`, `-h`/`--help`), parsed as
`build/macos-setup.sh` parses it. The full setup generates the cpanfile, then
installs with `sudo apt-get` the distribution's `perl`, `bash`, `tmux`,
`python3`, `python3-numpy`, `python3-scipy`, and the package of each cpanfile
module named in the script's module-to-package table (with `--dev-deps` the
develop block's, with `--package` `libpar-packer-perl`). A cpanfile module not
in the table must load from Perl's own install; the setup stops naming it
otherwise, so a new module gets its package named before the setup passes.
The shell step runs condition 8 and adds nothing: the distribution's tools are
on its default `PATH`, so a login shell resolving others means a line the
developer owns. `--repair` is that step and the check.

Changes to `process/check-environment.pl` under D3: condition 5 removed; the
module probe judges a module's place against the Perl's built-in `@INC` only
(no setup directory on any host); condition 7's Linux place requires NumPy and
SciPy under `/usr/lib/python3/dist-packages`; the session-start message names
`./build/linux-setup.sh` and `--repair` on Linux. Records rewritten:
`docs/development-environment.md` (the Debian/Ubuntu row, conditions 3 and 5),
`README.md` § Install Dependencies and § Test-harness dependencies (the
manual `cpanm` and `pip`/venv steps replaced), `CLAUDE.md` § Build.

Runs on this host (Ubuntu 26.04.1), captured in the session's scratchpad:

| Run | Result |
|---|---|
| `--validate` before setup | exit 1: 3 FAIL (conditions 3, 7, 8), 1 note (4); no condition 5 |
| session-start message before setup | "Devel::Size does not load (2 more in the full report …) / Likely cause: modules were added or upgraded since the setup last ran / Fix: run ./build/linux-setup.sh." |
| `--dev-deps --package` | exit 0; 12 cpanfile modules load from Perl's own install; check 8 pass, 2 n/a; `perl -c ltl` OK; `pp` at `/usr/bin/pp` |
| full setup again | exit 0; apt: 0 newly installed; 8 pass |
| `--repair` | exit 0; "Nothing to add."; 8 pass |
| an unknown option | usage on stderr, exit 2 |

The session-start message for missing modules read "Likely cause: modules
were added or upgraded since the setup last ran", wrong on a host where setup
never ran; it now reads "the setup has not run on this host, or modules were
added or upgraded since it last ran" (shown with two modules hidden by an
`@INC` hook). Condition 10 is not expected on Linux: the screenshot tool
draws its PNG with WebKit on macOS (`features/598-screenshot-capture.md` D23).
Each Linux test case's result is recorded under it.

AC7 (a session started on a wrong `PATH`) passed, run by the architect.
AC16's Linux part (every harness starts) and AC14 passed.

Stage 2 complete, 2026-10-23: every Linux test case passes.

## Stage 3: the Windows development host

### The check on this host, as found (2026-10-24)

Windows 11 on ARM64, Git for Windows (`/clangarm64`), Strawberry Perl 5.42.3
at `C:\Strawberry\perl\bin`, Git's own Perl 5.42.2 at `/usr/bin/perl`. Setup's
managed block in `~/.bashrc` prepends Strawberry Perl, and `~/.bash_profile`
sources `~/.bashrc`. Claude Code was started from a `cmd.exe` window.

The session-start hook reported 5 pass, 3 FAIL, 0 note, 2 n/a:

| # | Result | Found |
|---|---|---|
| 1, 6, 7, 11 | pass | |
| 2 | FAIL | `/usr/bin/perl` (5.42.2), Git's own |
| 3 | FAIL | 8 of 21 runtime modules do not load under Git's Perl |
| 4 | FAIL | "build/cpanfile.windows lists no modules, or cannot be read": the file has no develop block, and the empty develop list is reported as a FAIL, where the conditions table makes condition 4 a note |
| 8 | pass | login (`-lc`) and new tab (`-lic`) resolve Strawberry Perl; plain (`-c`) resolves `/usr/bin/perl` |

The message shown to the developer read "Likely cause: Claude Code was
started with a PATH that differs from a new terminal's … Fix: quit Claude
Code, open a new terminal, and start it there." On Windows that fix cannot
work. Measured by starting Git's `bin\bash.exe -c 'command -v perl'` from
PowerShell:

| Environment | `perl` resolved |
|---|---|
| Claude Code's own `PATH` | `/usr/bin/perl` |
| Strawberry Perl first in the inherited Windows `PATH` | `/usr/bin/perl`: the launcher puts `/clangarm64/bin:/usr/bin:~/bin` in front of whatever `PATH` it inherits |
| `BASH_ENV` set to `~/.bashrc` | `/c/Strawberry/perl/bin/perl`, Git's `/usr/bin` second |

Claude Code runs its hooks in that plain shell, which reads no startup file,
so the managed block never applies to them, whatever terminal Claude Code was
started from. `user_message` in the check has no Windows case: with
condition 8 passing it falls to the branch written for macOS and Linux.
`BASH_ENV` was set as a Windows user variable on this host (`setx`), with the
architect's approval; Windows setup does not set it.

With `BASH_ENV` in effect, the check runs under Strawberry Perl and cannot
start any tool: `run_capture`'s `open( $fh, '-|' )` is not supported there,
and `cmd.exe` reports "'-' is not recognized as an internal or external
command" once per tool. The report then reads 2 pass, 5 FAIL (3, 4, 6, 8, 11),
each from a tool that was never started. This is the adaptation of
`run_capture` that § Resuming hands to this stage.

The gap behind the wrong message (architect, 2026-10-24): `user_message` has
no story for Windows. Every branch names a cause and a fix written for macOS
and Linux (a new terminal, `--repair`), so on Windows the message can name
neither the cause nor a fix that works. D17 gives Windows a story of its own.

### The Windows story (agreed by the architect, 2026-10-24, to be tried on this host)

What the session-start message tells the developer on Windows, per failure:

| What the check finds | Cause on Windows | Fix the message names |
|---|---|---|
| no `perl` on `PATH` (1) | Strawberry Perl not installed, or no Git Bash, so Claude Code fell back to PowerShell | run the Windows setup |
| `perl` is Git's own `/usr/bin/perl`, a login shell finds Strawberry Perl (2) | `BASH_ENV` not set, so the plain shell the hooks run in never reads `~/.bashrc` | run the Windows setup, then quit Claude Code and every terminal window and start again: a new user variable reaches only processes started after it |
| `perl` is Git's own, and so is a login shell's (2 and 8) | the `~/.bashrc` block missing, or a later line putting Git's directories back in front | run the Windows setup |
| Strawberry Perl first, modules missing (3) | setup not run, Strawberry Perl reinstalled, or `build/cpanfile.windows` behind `build/cpanfile` | run the Windows setup |
| a module from outside Strawberry Perl, or two copies (3) | a `PERL5LIB` entry, or a `cpanm` copy beside Strawberry Perl's own | remove that copy, then start again |
| `python3` does not import NumPy or SciPy (7, a note) | the `~/bin/python3` wrapper missing, so the Microsoft Store stub answers, or the modules installed for another Python | run the Windows setup |
| CRLF checkout (11) | as before | clone again with `core.autocrlf=false` |

"Run the Windows setup" is the full setup until this stage writes its
`--repair`. The story needs three changes to the check: tools started under
Strawberry Perl; condition 8 on Windows judging the plain `bash -c` the hooks
run in as well as the login shell, with `BASH_ENV` kept in its clean
environment; and an empty develop block reported as condition 4's note.

## Troubleshooting a failed condition

The entries live in `docs/development-environment.md` § Troubleshooting a
failed condition, the standing document for setting up a development host
and reading the environment check, where the check, the setup and the
profiling preflight point. They name no issue: on AC7's run the session
start's agent reply, reading pointers into this issue's document, framed a
wrong `PATH` against the issue.
