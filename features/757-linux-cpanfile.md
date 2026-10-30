# 757: a Linux-specific variant of the cpanfile

Issue: #757 (a Linux-specific variant of the cpanfile, requiring only the
modules `ltl` loads on Linux). Parent: #729 (process, tests and build).
Blocks: #709 (`-mem` misses stores and working memory), from its delivery plan
drop 2 on.

Status: delivery, from 2026-10-30, on branch `757-cpanfile-per-platform`.
Drop 1 is delivered (§ Delivery plan › Progress). The contracts of the surfaces
touched are confirmed by the architect; the records sweep, the findings, the
architect's direction and the scope are recorded below, and the acceptance
criteria are agreed (architect, 2026-10-28), with his corrections to 3, 5 and 6
applied.

## What it is for

#709's drop 2 reads macOS's kept peak memory through `BSD::Resource`
(`features/memory-tracking-improvements.md` § Issue #709 › Decisions, D2: macOS
reads the resident high-water mark from `getrusage` through `BSD::Resource`).
macOS needs the module installed and packed into its binary; Linux and Windows
never load it, and no path of theirs may require it. Today `build/cpanfile`
serves macOS and Linux alike, so a module declared there for macOS becomes a
requirement of every Linux path that reads it.

Scope, as the architect set it (2026-10-28, on the issue): this issue owns the
build side of `BSD::Resource`, declaring it for macOS, installing it in macOS
setup and the macOS release binary carrying it; #709 keeps the reading and its
fallback.

## Contract of the surfaces touched (confirmed by the architect, 2026-10-28)

Which cpanfile each reader reads, as found on `release/0.20.0`:

| Reader | Host | Reads |
|---|---|---|
| `build/macos-setup.sh` (also the CI macOS job) | macOS | `build/cpanfile` |
| `process/check-environment.pl`, conditions 3 and 4 | macOS | `build/cpanfile` |
| `build/macos-package.sh` (`pp`) | macOS | no cpanfile: `pp` packs what it traces in `ltl` |
| `build/linux-setup.sh` | Linux | `build/cpanfile` |
| `process/check-environment.pl`, conditions 3 and 4 | Linux | `build/cpanfile` |
| `build/ubuntu-package.sh` (also the CI Ubuntu job) | Linux container | `build/cpanfile` |
| `tests/profile/profiling-preflight.sh` | Linux | `build/cpanfile` |
| `build/install-deps.sh` | any | `cpanfile` in the current directory |
| `build/windows-setup.ps1`, `build/windows-package.sh`, the check, the preflight | Windows | `build/cpanfile.windows` |

| Surface | Contract | Record |
|---|---|---|
| The cpanfiles | "The cpanfiles are generated inputs, never the source of truth (architect, 2026-10-15)" | `features/memory-tracking-improvements.md` § Issue #146 › Scope, item 3 |
| `build/generate-cpanfile.sh` | Lists the modules `ltl` loads with `use` or `require`, pragmas dropped, sorted in byte order, LF endings; a Windows-only module goes in `WINDOWS_ONLY_MODULES`, a Unix-only one in `UNIX_ONLY_MODULES`. "The generator stays the sole author of the file … two runs of `generate-cpanfile.sh` produce byte-identical output." The develop block (`Devel::NYTProf`) is a literal it appends, to both files | `features/544-upgrade-safe-profiling-setup.md` D4 (the profiler as a develop block the generator appends), D5a as amended (the Windows file carries it too); `features/412-notice-surfaces-research.md` § 1.1 |
| `build/linux-setup.sh` | Generates the cpanfile, then installs the distribution's package of each module in its module-to-package table. "A cpanfile module not in the table must load from Perl's own install; the setup stops naming it otherwise" | `features/750-interpreter-resolution.md` § `build/linux-setup.sh` (D3: the distribution's packages) |
| The environment check, condition 3 (and 4) | "it loads every runtime module the cpanfile requires, each from the Perl's own install or the setup's, once"; the file per host is `build/cpanfile` on macOS and Linux, `build/cpanfile.windows` on Windows; condition 4, the develop block, is a note | `features/750-interpreter-resolution.md` § Phase 4: the expected conditions |
| `build/ubuntu-package.sh` | "runs `cpanm --notest --installdeps .` against `build/cpanfile`, packs the binary and verifies it with `--version`"; the default install never resolves the develop block | `features/544-upgrade-safe-profiling-setup.md` D10 (the Ubuntu container build unchanged) |
| `build/macos-setup.sh` | "`./generate-cpanfile.sh`; `cpanm --notest --installdeps .`, with `--with-develop` under `--dev-deps`" | `features/750-interpreter-resolution.md` § Step 3 |
| The packagers (`pp`) | "`build/macos-package.sh` and `build/ubuntu-package.sh` both invoke `pp` with no inclusion flags … `pp` decides what to bundle by tracing the script's own dependencies, not by reading the cpanfile … adding an inclusion flag to either would need this restated" | `features/544-upgrade-safe-profiling-setup.md` D4 |
| The profiling preflight | "the install the preflight runs is `cpanm --notest --installdeps --with-develop .` from `build/`": "one declaration, one install path". Windows reads its own file, every other host `build/cpanfile` | `features/544-upgrade-safe-profiling-setup.md` D11; `tests/profile/profiling-preflight.sh` |
| `BSD::Resource` | "The module is loaded on macOS only, as `Win32::API` is on Windows only. Declaring it for macOS, installing it in macOS setup and carrying it in the macOS binary belong to #757." Moved here: criterion 7, "the packaged macOS binary carries `BSD::Resource` and reports the kept peak"; criterion 8, "`build/generate-cpanfile.sh` names `BSD::Resource` for macOS only, in no Linux or Windows cpanfile" | `features/memory-tracking-improvements.md` § Issue #709 › Decisions, D2; › Acceptance criteria |
| `docs/development-environment.md`, condition 3 | A missing module's likely cause: "on Linux, a new module also needs its package named in `build/linux-setup.sh`, which stops until it is" | `docs/development-environment.md`, the conditions table |

## Records sweep (2026-10-28)

Searched with `./process/find-records.sh --issues` for `cpanfile`,
`BSD::Resource`, `generate-cpanfile`, `linux-setup`, `check-environment`,
`ubuntu-package`, `macos-setup` and `macos-package` (exit 0).

| Record | Read or dismissed |
|---|---|
| `features/750-interpreter-resolution.md` | Read: § Phase 4: the expected conditions, § Decisions, § Step 3, § `build/linux-setup.sh`, § Stage 4 › The container builds. Owns condition 3's file per host and the Linux setup |
| `features/544-upgrade-safe-profiling-setup.md` | Read: D4, D5a, D10, D11, § cpanfile shape. Owns the develop block, the flagless `pp`, the preflight's install |
| `features/memory-tracking-improvements.md` | Read: § Issue #709 (Status, Resuming, D2, Acceptance criteria, Delivery plan, its edges); § Issue #146 › Scope (the generated-inputs rule) |
| `features/412-notice-surfaces-research.md` | Read: § 1.1 Modules and packaging, the routing lists and `Win32::API` loaded at run time inside `eval` |
| `features/windows-automated-build.md` | Read: § Implementation Status › Completed, the origin of the Unix and Windows split; nothing beyond what the generator does today |
| `features/227-binary-smoke-coverage.md` | Read: § 3, "`pp`'s static `Module::ScanDeps` misses a runtime-only `require` … Reproduced historically with `Win32::API`"; bears on the binary carrying the module |
| `features/503-yaml-aggregate-export.md` | Read: D17 and drop 4, the precedent for a new module: regenerate both cpanfiles, install with `build/install-deps.sh` run from `build/`, prove the platform builds, add `-M` only if a build lacks the module |
| `docs/development-environment.md` | Read: the conditions table, condition 3 |
| `features/ci-build.md` | Read; dismissed: the CI design of v0.8.2 and the files it changed; the steps the workflow runs today are read from `.github/workflows/release-build.yml` |
| `features/621-generated-read-loop-body.md` | Read (the packaging table); dismissed: names the Perl each packager runs, nothing of the module list |
| `features/datetime-to-timepiece-migration.md` | Read (its plan and files); dismissed: a past dependency removal, noting only that the cpanfile is generated |
| `docs/toolchain-guidance.md` | Read; dismissed: the Windows setup installs `build/cpanfile.windows`, which this issue does not change |
| `releases/v0.8.2.md`, `releases/v0.10.3.md`, `releases/v0.12.2.md` | Dismissed: historical release notes |
| #85 (closed, a macOS build missing `Devel::Size`), #106 (closed, the Strawberry Perl download), #387 (open, `YAML::PP` as a hard dependency), #720 (closed, the read path in the packed binaries) | Dismissed: none routes a module by platform or changes which file a reader reads |
| #146, #544, #709, #750 | Read through their feature docs above |

## Findings (2026-10-28)

Every path, section and commit the issue cites exists, and the native edge
"#757 blocks #709" is in place.

**A fourth Linux reader, not in the issue's list.**
`tests/profile/profiling-preflight.sh` sets `CPANFILE="cpanfile"` on every host
but Windows. When the profiler is missing and `cpanm` is present, it runs
`cpanm --notest --cpanfile cpanfile --installdeps --with-develop .`, which
installs the runtime modules as well as the develop block. On a Linux host with
`cpanm`, a macOS-only module in `build/cpanfile` would be built and installed.

**`build/install-deps.sh` reads `cpanfile` in the current directory, whatever
the host.** It generates the file when absent and runs `cpanm --notest
--installdeps .`. No script or workflow calls it: a search outside `features/`
finds only its own header. It has been run by hand under direction:
`features/503-yaml-aggregate-export.md` D17 installed `YAML::PP` with it, "run
from the build path" (architect, 2026-09-02).
`features/544-upgrade-safe-profiling-setup.md` D4 counts it among "every build
path".

**Nothing on macOS installs or packs `BSD::Resource` until `ltl` loads it.**
`generate_cpanfile()` in `build/generate-cpanfile.sh` lists the modules matched
by `^\s*(?:use|require)\s+([A-Za-z0-9_:]+)` in `ltl`, and `ltl` has no line
naming `BSD::Resource` (`grep -c` 0); #709's drop 2 adds it. `pp` packs what
it traces in `ltl` (544 D4, above). So after this issue alone, under the
generated-inputs rule, no cpanfile names the module, `build/macos-setup.sh`
does not install it, and the macOS binary does not carry it. Two lines of #709's
record assume otherwise:
- § Resuming: "The issue branch needs none of #757's commits, since this issue
  changes no build file. What it needs is `BSD::Resource` installed on the macOS
  host by #757's macOS setup, for criterion 1".
- § Delivery plan, drop 2: "No build file changes here: #757 … declares
  `BSD::Resource` for macOS, installs it in macOS setup and carries it in the
  macOS binary."

**Criterion 7's second half reads #709's code.** "The packaged macOS binary
carries `BSD::Resource` and reports the kept peak": the kept peak is the reading
#709's drop 2 adds, and #709 cannot start drop 2 before this issue is
delivered. The issue's done-when carries the same half: "the macOS release
binary carries it and reads the peak with no module installed where it runs".

**Observation: two texts compare the Windows file with `build/cpanfile`.** The
environment check's Windows session-start message gives "`build/cpanfile.windows`
is behind `build/cpanfile`" as a likely cause of a missing module, and
`docs/development-environment.md`'s condition 3 row "`build/cpanfile.windows`
differs from `build/cpanfile`". The two files differ by `Win32::API` on every
host today, and since #146 the Windows setup generates its file before
installing from it. Once `build/cpanfile` is macOS's alone, it differs from the
Windows file by `BSD::Resource` as well.

## Direction (architect, 2026-10-28)

Each platform has its own cpanfile: Linux, macOS and Windows. The generator
detects the platform it runs on and writes that platform's file, and every
consumer, the image builds included, reads its own platform's file. The
cpanfiles are generated from the code, so a module enters a platform's file
when `ltl` loads it on that platform; when that happens is not this issue's to
schedule. This settles the finding "Nothing on macOS installs or packs
`BSD::Resource` until `ltl` loads it", and the finding on
`build/install-deps.sh`: it reads its host's file.

## Scope: one generated file per platform

| Platform | File | Written by `build/generate-cpanfile.sh` | Read by |
|---|---|---|---|
| macOS | `build/cpanfile.macos` | on a macOS host, or with `macos` | `build/macos-setup.sh` (and the CI macOS job); the environment check, conditions 3 and 4; the profiling preflight; `build/install-deps.sh` |
| Linux | `build/cpanfile.linux` | on a Linux host, or with `linux` | `build/linux-setup.sh`; the environment check; the profiling preflight; `build/install-deps.sh`; `build/ubuntu-package.sh`'s container (and the CI Ubuntu job) |
| Windows | `build/cpanfile.windows` | on a Windows host (Git Bash), or with `windows` | `build/windows-setup.ps1`; the environment check; the profiling preflight; `build/windows-package.sh`'s Docker and Wine build (and the CI Windows job) |

Recorded with it, each the one sensible option:
- With no platform argument the generator reads the host from `uname -s` and
  writes that host's file alone. A platform argument (`macos`, `linux`,
  `windows`, `all`) writes the named file whatever the host, for the packagers
  that build for a platform other than the host's: Windows from a Linux runner
  or a macOS host, the Ubuntu container from a macOS host. The `unix` argument
  goes with the file it wrote.
- `build/cpanfile` is renamed `build/cpanfile.macos`, so the three files are
  named alike, `build/cpanfile.<platform>`, and no reader names
  `build/cpanfile`.
- Each packaging script generates its target platform's file before reading
  it, as the three setups already do, so a build never reads a file written
  for another host. The CI Windows job runs on `ubuntu-latest`, where the
  generator alone would write the Linux file.
- The generator's platform lists route a module loaded on some platforms only:
  `Win32::API` to the Windows file alone, as today, and `BSD::Resource` to the
  macOS file alone.
- Every text naming `build/cpanfile` names the platform's file instead: the
  environment check's Windows message and `docs/development-environment.md`'s
  condition 3 row (both compare the Windows file with `build/cpanfile`),
  `build/packaging-notes` and the packagers' header comments.

## Acceptance criteria

Agreed by the architect, 2026-10-28. His corrections: criterion 3 is the rename
of `build/cpanfile` to the per-platform naming; criterion 5 includes the Windows
build under Wine writing the Windows file; the builds run locally. The
macOS development host is a virtual machine without nested virtualization, so
no container runtime starts there (below); the builds run on GitHub Actions
instead (architect, 2026-10-28).

1. **With no platform argument, the generator writes the host's file alone.**
   *Assertable.* Observable: on macOS only `build/cpanfile.macos` is written,
   on Linux only `build/cpanfile.linux`, under Git Bash on Windows only
   `build/cpanfile.windows`. Validation: run on the macOS development host, on
   Linux by the CI Ubuntu job of the release workflow's `workflow_dispatch` run
   on the issue branch (its log names the file written), and with a `uname`
   first on PATH that reports `MINGW64_NT-10.0` as Git Bash does; the files
   written are listed after each.
2. **With a platform argument, it writes that platform's file whatever the
   host.** *Assertable.* Observable: `macos`, `linux` and `windows` each write
   that file alone, `all` writes the three. Validation: each run on macOS.
3. **The three files are named alike, `build/cpanfile.<platform>`.**
   *Assertable.* Observable: `build/cpanfile` is renamed
   `build/cpanfile.macos`, beside `build/cpanfile.linux` and
   `build/cpanfile.windows`, and `git log --follow build/cpanfile.macos` carries
   the old file's history. The rename changes no module list: the macOS and
   Linux files equal `git show f72c2167:build/cpanfile` byte for byte, the
   Windows file equals `git show f72c2167:build/cpanfile.windows`, and two
   runs of the generator are byte-identical.
4. **A module one platform loads is in that platform's file alone** (#709's
   criterion 8, moved here). *Assertable.* Observable: run on a scratch copy of
   `ltl` carrying a `require BSD::Resource` line, passed as the generator's
   script name, the macOS file names `BSD::Resource` and the Linux and Windows
   files do not; `Win32::API` is in the Windows file alone.
5. **Every reader reads its platform's file, and none names `build/cpanfile`.**
   *Assertable.* Observable: `git grep` for `build/cpanfile` not followed by a
   platform suffix, outside `features/` and `releases/`, returns nothing; each
   reader runs to its end on its host. The Windows build under Wine, run on a
   host that is not Windows, writes `build/cpanfile.windows` itself and installs
   from it, as the CI Windows job does on `ubuntu-latest`, where the generator
   alone writes the Linux file. Validation, each reader in the scope table: on
   macOS `build/macos-setup.sh`, the environment check (conditions 3 and 4),
   the preflight with `LTL_PROFILING_INSTALL=0` and `build/install-deps.sh`; in
   GitHub's `ubuntu-latest` runner `build/linux-setup.sh`, the check and the
   preflight, by a temporary job on the issue branch that runs on each push
   there and is deleted before the PR (architect, 2026-10-28); the
   builds by a `workflow_dispatch` run of the release workflow on the issue
   branch, whose macOS, Ubuntu (amd64, arm64) and Windows jobs each produce a
   binary answering `--version`. Its Windows job runs on `ubuntu-latest`, the
   case above.
6. **The macOS binary carries the macOS file's modules** (#709's criterion 7,
   moved here). *Assertable.* Observable: the scratch copy of `ltl` that
   requires `BSD::Resource`, packed on the macOS development host with `pp` as
   `build/macos-package.sh` invokes it, with the module installed, lists
   `BSD/Resource.pm` under `unzip -l`. The criterion's other half, the binary
   reporting the kept peak, reads #709's reading and is checked on the binary
   built once that reading is in `ltl`.

No container runtime runs on the macOS development host (2026-10-28). It is a
virtual machine (`hw.model` `VirtualMac2,1`, "Apple M1 Pro (Virtual)") with no
hypervisor support (`kern.hv_support` 0). Rancher Desktop, once installed,
stops with "Virtualization does not appear to be supported on your machine",
and Apple's virtualization framework with "Virtualization is not available on
this hardware"; Apple supports a virtual machine inside one only on M3 chips or
later.

## Delivery plan

Branch `757-cpanfile-per-platform` off `release/0.20.0`, `$version_number`
`0.20.0-757`. No hot path is touched, so no before benchmark.

1. **Drop 1: one file per platform, and every reader on this host's side.**
   `git mv build/cpanfile build/cpanfile.macos`; the generator detects the
   host, takes `macos`, `linux`, `windows` or `all`, routes `BSD::Resource` to
   the macOS file alone and writes `build/cpanfile.linux`; the three files
   regenerated and committed. In the same commit, so no reader names a missing
   file: `build/macos-setup.sh`, `build/linux-setup.sh`, the environment check's
   conditions 3 and 4 and its Windows message, the profiling preflight,
   `build/install-deps.sh`, `docs/development-environment.md`'s condition 3 row,
   `build/packaging-notes`. Proven on this host: criteria 1 (macOS, and Git
   Bash's `uname`), 2, 3 and 4, and criterion 5's macOS runs.
2. **Drop 2: the packagers and CI.** `build/ubuntu-package.sh` and
   `build/windows-package.sh` generate their target platform's file before
   reading it; the CI jobs' separate generate steps go; the temporary Linux job
   is added. Proven by its push run (criterion 5's Linux runs) and a
   `workflow_dispatch` run of the release workflow on the issue branch
   (criterion 1 on Linux, criterion 5's builds).
3. **Criterion 6 on this host.** `BSD::Resource` installed into the
   development Perl, the scratch copy of `ltl` packed as
   `build/macos-package.sh` packs, `unzip -l` read. No commit.

### Progress

**Drop 1, delivered 2026-10-30** (8b8b4601 on `757-cpanfile-per-platform`).
Evidence, from the macOS development host:
- Criterion 1: with no platform argument, a scratch copy of the generator
  wrote `cpanfile.macos` alone under the host's `uname` (`Darwin`),
  `cpanfile.windows` alone under a `uname` first on PATH reporting
  `MINGW64_NT-10.0-26100`, and `cpanfile.linux` alone under one reporting
  `Linux`. The CI Ubuntu run on Linux is drop 2's.
- Criterion 2: `macos`, `linux` and `windows` each wrote that file alone, `all`
  the three; `unix` and an unknown name exit 1 having written nothing.
- Criterion 3: the macOS and Linux files equal `git show f72c2167:build/cpanfile`
  byte for byte, the Windows file `git show f72c2167:build/cpanfile.windows`;
  two runs are byte-identical; `git log --follow` on `build/cpanfile.macos`
  reaches the old file's history (#146's regeneration, a698384d, and earlier).
  Git's status pairs the rename with `build/cpanfile.linux`, the two contents
  being identical; `--follow` finds the history from either.
- Criterion 4: a scratch `ltl` carrying `require BSD::Resource`, passed as the
  script name with `all`: the macOS file names `BSD::Resource` and the Linux
  and Windows files do not; `Win32::API` is in the Windows file alone.
- Criterion 5, macOS runs, each exit 0: the environment check, conditions 3
  and 4, pass, and with a module that does not exist planted in
  `build/cpanfile.macos` condition 3 fails naming it and `build/cpanfile.macos`;
  the preflight with `LTL_PROFILING_INSTALL=0`, its trace setting
  `CPANFILE=cpanfile.macos`; `build/install-deps.sh` from `build/`, running
  `cpanm --notest --cpanfile cpanfile.macos --installdeps .`;
  `build/macos-setup.sh` and `build/macos-setup.sh --dev-deps` to their end,
  installing with `--cpanfile cpanfile.macos`, the check after it 9 pass,
  0 FAIL. The setup ran with `HOMEBREW_NO_AUTO_UPDATE=1` and
  `HOMEBREW_NO_INSTALL_UPGRADE=1`, so its `brew install` steps upgraded no
  formula on the host (`python@3.15` was outdated); the cpanfile step ran
  unchanged. After drop 1 the grep for `build/cpanfile` with no suffix finds
  only `build/ubuntu-package.sh`, drop 2's.

Recorded with drop 1, each the one sensible option:
- The environment check's Windows message gave "`build/cpanfile.windows` is
  behind `build/cpanfile`" as a cause of a missing module. Each file is now
  generated from `ltl` for its platform, so the comparison has no meaning; the
  cause reads "modules were added or upgraded since it last ran", as the other
  hosts' message does. `docs/development-environment.md`'s condition 3 row
  drops the comparison in the same way and names the three files under "the
  host's cpanfile".
- `build/install-deps.sh` reads the host from `uname -s` with the mapping the
  generator and the preflight use.

Observation: `prototype/720-packed-generated-loop/pack-linux.sh` runs
`cpanm --notest --installdeps .` in `build/`, which reads a file named
`cpanfile` that no longer exists. It is the instrument of a closed issue's
measurement and is left as it ran; the grep of criterion 5 does not see it,
since it names no `build/cpanfile`.

Completion gate: the temporary job deleted first. The diff touches no line of
`ltl` and no harness, fixture or expectation, and no harness runs the changed
scripts, so the before/after benchmark and the full suite are skipped and the
skip is recorded in the completion comment (`docs/process/workflow.md` § 3,
scope test). No release-notes bullet: nothing a user of `ltl` observes changes.
