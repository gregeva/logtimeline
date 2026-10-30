# Development environment

Every consumer of a development host (the developer's shell, Claude Code and
its hooks, the harnesses, profiling, benchmarks, builds) runs one Perl, one
bash 4 or later and one Python: the ones the host's setup installs, with the
modules the project needs. Which of them comes first on `PATH` is the setup's
job; scripts take `perl`, `bash` and `python3` from `PATH` and never name one
by where it is installed. The one exception is the Perl that runs the
environment check at session start on Windows: Git's own `/usr/bin/perl`,
present wherever Git Bash is. The check needs only a Perl to run, and judges
the `perl` on `PATH` by starting it.

## The environment check

`process/check-environment.pl` judges whether the host is set up that way,
whatever configured it. It is read-only, needs only Perl's core modules, and
runs:

- by hand, on any host: `perl process/check-environment.pl`;
- through each host's setup: `./build/macos-setup.sh --validate`;
- at the end of a full setup;
- at every Claude Code session start, resume, clear and compaction, as a
  hook in `.claude/settings.json`, run by the `perl` on `PATH`, or on Windows
  by Git's own. When a condition fails, the developer is
  shown what is wrong, the likely scenario and the command to run; the agent
  receives the full report and diagnoses it from the entries below.

It reports, per condition, `pass`, `FAIL`, `note` (something optional is
missing) or `n/a` (not applicable on this host), with what it expected and
what it found, the Perl it ran under and the `PATH` it saw. It exits 0 when
nothing fails, 1 otherwise.

| Host | Full setup | Add only what is missing from the shell configuration | Check only |
|---|---|---|---|
| macOS (Homebrew required) | `./build/macos-setup.sh` (`--dev-deps` adds the profiler, `--package` PAR::Packer) | `./build/macos-setup.sh --repair` | `./build/macos-setup.sh --validate` |
| Windows (from PowerShell) | `powershell -NoProfile -ExecutionPolicy Bypass -File .\build\windows-setup.ps1` (`--dev-deps` adds the profiler, `--package` PAR::Packer) | the same, with `--repair` | the same, with `--validate` |
| Debian/Ubuntu | `./build/linux-setup.sh` (`--dev-deps` adds the profiler, `--package` PAR::Packer) | `./build/linux-setup.sh --repair` (adds nothing: the distribution's tools are on its default `PATH`) | `./build/linux-setup.sh --validate` |

## Troubleshooting a failed condition

Work out the cause on the host from what the report shows and the entry
below, then fix the cause, not the symptom: no script is edited to name an
interpreter, and no `PATH` line is added by hand outside setup's marked
block. A failed check describes the host's environment; it is never a defect
of the repository or of the work in progress.

Two things hold for every entry:

- **The check sees the environment of whatever started it.** At session start
  that is Claude Code's own process, inherited from the shell Claude Code was
  started from, not the agent's Bash tool and not a fresh terminal. A
  condition can fail in the session and pass in a new terminal, or the
  reverse; condition 8's report shows what a clean login shell and a new
  terminal tab resolve, to compare with the `PATH` the check saw.
- **Which shell files are read depends on how the shell was started.** On
  macOS, a login zsh (every new terminal tab, and what is started from it)
  reads `~/.zprofile`, after `/etc/zprofile` has run `path_helper`, which puts
  the system directories in front; an interactive zsh reads `~/.zshrc`; a
  plain `zsh -c` reads only `~/.zshenv`. Lines that put the tools first in
  `~/.zshrc` alone reach a terminal tab but no login shell started by a
  program. A context that reads none of these files resolves the system's
  tools.

| # | What a failure means | Where it has come from |
|---|---|---|
| 1 | no `perl` on the `PATH` the check saw | the host is not set up, or the process that started the check did not inherit the setup's `PATH` (a Windows host without Git Bash, where Claude Code falls back to PowerShell, is treated as not set up) |
| 2 | another Perl comes first | `PATH` order: Homebrew's line, or setup's addition, missing from a file this context reads (condition 8 shows which shell modes resolve what), or a later line in a shell file, or `path_helper` on macOS, putting the system directories back in front; Claude Code started from a shell whose `PATH` was changed by hand. On Windows, Claude Code runs its hooks in a plain Git Bash shell, which puts Git's own directories, and its Perl, in front of the `PATH` it inherits and reads no startup file: `BASH_ENV`, which the Windows setup sets to `~/.bashrc` as a user variable, not set, set to another file, or set after Claude Code started (condition 8 shows a login shell finding Strawberry Perl); or the `~/.bashrc` block missing, or followed by a line putting Git's directories back in front (a login shell finds Git's Perl too) |
| 3 | the right Perl lacks a runtime module, loads one from outside its install, or finds two copies | a module from outside: a `PERL5LIB` or `PERLLIB` entry, which no setup makes, named in the report; two copies: a module installed again outside Perl's core, such as a `cpanm` or `local::lib` copy beside the distribution's `lib*-perl` package, both listed. Missing: on macOS, a Homebrew Perl upgrade across a minor version leaves the modules installed for the old version in the old version's directory; the host's cpanfile (`build/cpanfile.macos`, `build/cpanfile.linux` or `build/cpanfile.windows`) changed since setup ran (on Linux, a new module also needs its package named in `build/linux-setup.sh`, which stops until it is); on Windows, Strawberry Perl reinstalled. Installing is the full setup's job, not `--repair`'s |
| 4 | note: the profiler is not installed | expected unless setup ran with `--dev-deps`; the same upgrade cause as 3 applies |
| 5 | retired: no setup installs modules under the home, so there is nothing to make visible; the number is not reused | |
| 6 | the first `bash` is older than 4 | the system's bash ahead of the setup's; macOS's `/bin/bash` is 3.2. The same `PATH` causes as 2 |
| 7 | `python3` does not import NumPy or SciPy, or loads one from outside the setup's install | on every host, a `pip install --user` copy (the report names the user's `site-packages`), or a second copy of a module (the report lists each with its version and metadata directory); another Python ahead of the setup's (macOS `/usr/bin/python3`; on Windows the Microsoft Store stub), or the modules installed for a different Python than the one on `PATH`. On macOS: Homebrew's Python present only as a versioned formula another formula depends on, which links `python3.x` and no `python3`, so `/usr/bin/python3` comes first; a module installed with `pip` into Homebrew Python's `site-packages`, which shadows the formula's own and can leave the formula unlinked (`brew link --dry-run <formula>` shows what is not linked; the full setup links it once the copy is removed); a `pip` install that Homebrew's formula later overwrote leaves `pip`'s metadata behind, and `pip uninstall` would remove every path in that metadata's `RECORD`, which Homebrew's files now occupy |
| 8 | a login shell from a clean environment resolves different tools | the lines that put the tools first are in a file a login shell does not read (on macOS, `~/.zshrc` alone: the report then shows a new tab right and a login shell wrong), or another file read after them reorders `PATH`. `--repair` adds the missing piece to `~/.zprofile`. On Windows: setup's managed blocks in `~/.bashrc` and `~/.bash_profile`, or its `~/bin/python3` wrapper, missing. When every mode resolves the same tool as the `PATH` the check saw, the shell files are not the cause: the failure repeats condition 2's, 6's or 7's, and that entry applies |
| 9 | no `tmux` on macOS or Linux | the setup has not run on this host, or tmux was removed; the terminal-interface navigation tests cannot run without it, so the full harness suite cannot pass. The full setup installs it (Homebrew's formula on macOS, the distribution's package on Linux) |
| 10 | note: no screenshot tools | screenshot capture cannot run on this host |
| 11 | Windows: `core.autocrlf` is not `false` | the clone was made without `-c core.autocrlf=false`, or a global setting overrides the repository's; scripts check out with CRLF endings and fail in Git Bash |
