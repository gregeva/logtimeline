# 757: a Linux-specific variant of the cpanfile

Issue: #757 (a Linux-specific variant of the cpanfile, requiring only the
modules `ltl` loads on Linux). Parent: #729 (process, tests and build).
Blocks: #709 (`-mem` misses stores and working memory), from its delivery plan
drop 2 on.

Status: specification stage, from 2026-10-28. The contracts of the surfaces
touched are confirmed by the architect; the records sweep and the findings are
recorded below.

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
