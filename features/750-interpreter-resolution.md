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
| The agent's Bash tool | inherits the environment of the process that started Claude Code; in this session a terminal's interactive shell | Homebrew | Homebrew 5 | Homebrew | measured, this session only |
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

### Phase 3: how the wrong interpreter has been reached (in progress)

The architect starts Claude Code from a terminal, never from the desktop app,
so the agent's shell inherits the interactive environment and its `PATH`
(measured in this session: Homebrew Perl, bash and Python). The
non-interactive shell above therefore does not explain the agent's past use
of the system Perl in a terminal-started session, unless `~/.zshrc` did not
yet carry the Homebrew lines at the time; its comment matches the wording
`README.md` gained when the harnesses started refusing bash 3.2 (2026-09-24).

Cases on record, found by searching issues and commit messages for
"system Perl":

| Mechanism | Case | What was observed |
|---|---|---|
| A tool script found on `PATH` carries the shebang of another Perl | #85 (the macOS build missed `Devel::Size`) | bare `pp` ran under the system Perl's PAR::Packer, which could not see the modules installed for the active Perl; fixed by `perl -S pp` |
| An interpreter named by an absolute path that stops being right | #544 (profiling setup) | the pinned keg path no longer existed after a Homebrew Perl upgrade |
| A script whose first line names the system Perl | `#!/usr/bin/perl` in five prototype scripts (`prototype/426-revalidate-v6.pl`, `-v7.pl`, `-v8-rebless.pl`, `prototype/heatmap-mini.pl`, `prototype/heatmap-test.pl`) | run by their path, they start `/usr/bin/perl` whatever `PATH` holds; no recorded failure |
| A shell context that does not read `~/.zshrc` | phase 1, measured | system Perl, bash 3.2 and system Python |

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

To be derived from the analysis and agreed with the architect.

## Decisions

None yet.

## Acceptance criteria

To be derived from the agreed requirements (`docs/test-driven-development.md`),
each with its validation per host, enumerated over every occurrence above.
