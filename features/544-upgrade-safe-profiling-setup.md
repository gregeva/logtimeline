# Upgrade-safe profiling setup

Specification for issue #544 (the profiling workflow cannot run on the development
machine and its setup is not upgrade safe).

---

## Motivating consumer

**Every profiling task.** `features/nytprof-profiling-workflow.md` is the repository's
named method for locating a hot path, and `docs/perl-performance-optimization.md` sends
the reader there. `CLAUDE.md` § Checkpoints makes a measured premise mandatory before a
performance fix. Today none of that can be executed on the development machine: the
profiler module is not installed for the Perl that runs, and the HTML report tool the
workflow names by full path does not exist anywhere on disk. A profiling task therefore
either stops or substitutes an ad hoc measurement, which is what happened while
investigating issue #478 (the highlight decision is re-derived from the `-HL` category
suffix throughout the read loop).

**The next consumer is the prototype planned for issue #528** (a transform that assigns
arithmetic into a shared record lexical enlarges every retained duration). That prototype
measures a per-line cost in the read loop, which is exactly what the profiler is for. It
cannot start while the profiler cannot run.

**The second-order consumer is the record.** The profiling run whose capture lives in
`tests/profile/results/432-bytes-parity-capture/` completed with no HTML report and a
single `[WARN]` line, because `run-profile.sh` swallows a failure of the HTML tool. Its
own analysis note records that the workflow document named one Perl while the installed
toolchain was another. A profiling result that is quietly thinner than the method
describes is worse than a run that stops.

---

## Requirement

1. A profiling run works from a clean clone and after a Homebrew Perl upgrade, following
   `README.md` alone, with no version-specific path anywhere in the mechanism.
2. A profiling run whose profiler is missing installs it and continues; if the install
   cannot be done, the run stops with a non-zero exit and the exact manual command.
3. A profiling run never silently degrades. A missing HTML tool is a stop.
4. The development interpreter stays Homebrew Perl. The Perl that profiles and benchmarks
   is the Perl that builds the release binaries.

---

## Machine state and mechanism, for a reader who does not know Homebrew's layout

Homebrew installs each version of Perl into its own directory, called a keg, under
`$(brew --prefix)/Cellar/perl/<version>`, and links a small set of that keg's binaries
into `$(brew --prefix)/bin`, which is on PATH. `perl` on PATH is such a link and always
points at the currently active keg, so it survives an upgrade. Three consequences follow,
and together they are the whole defect.

**CPAN modules are installed per Perl minor version, inside that version's keg.** The
running Perl reports its module install directory as
`.../Cellar/perl/<version>/lib/perl5/site_perl/<major.minor>`. Nothing is shared between
versions and there is no cross-version fallback: the running Perl's `@INC` contains only
its own directories. A `brew upgrade perl` that crosses a minor version therefore creates
a new empty module directory and repoints the active keg. Every module previously
installed with `cpanm` becomes invisible in one step, with no message. On this machine
the profiler module is present for exactly one Perl, and it is not the current one.

**CPAN-installed scripts land in the keg's own `bin`, which Homebrew does not link onto
PATH.** The running Perl reports that directory as its script install location. This is
the fact the workflow document's standing rule "do not assume `nytprofhtml` is in PATH"
is reacting to. It is why the document pinned a full path, and the pin is what broke: the
whole `bin` directory of the older keg has since been removed, so neither the pinned tool
nor the older interpreter exists any more.

**A version in a path is a promise the package manager does not keep.** The workflow
document, and `run-profile.sh` with it, encoded one machine's state at one moment. The
document's own remedy paragraph asked the reader to hand-edit those paths after an
upgrade, which requires the reader to already know everything above. That is the mechanism
the issue rules out.

---

## Sweep: mechanisms to change, records left alone

A **mechanism** is executed or followed and must become version independent. A **record**
states what was measured on what; rewriting it would falsify the measurement.

### Mechanisms (change in this issue)

| Surface | What it carries today | What it becomes |
|---|---|---|
| `tests/profile/run-profile.sh` | `PERL` set to an absolute interpreter path and `NYTPROFHTML` set to a full path inside a named version's keg, under the comment "Hardcoded tool paths, no PATH dependency"; the HTML call wrapped so a failure prints a warning and continues | Preflight resolves both (decisions 6 and 7); the HTML failure becomes a stop |
| `tests/profile/run-profile.sh` closing "Next steps" text | Echoes an absolute interpreter path to the user | Repository-relative invocation |
| `tests/profile/extract-profile.pl` | Shebang naming an absolute Homebrew interpreter path | `#!/usr/bin/env perl`, matching `tests/profile/check-profile-labels.pl` |
| `features/nytprof-profiling-workflow.md` § Environment | A named Perl version and profiler version; a block of three full tool paths inside a named keg; the "If Homebrew upgrades Perl" paragraph instructing a hand edit | A statement of the requirement and how the tools are resolved; the self-install behaviour replaces the hand-edit paragraph |
| `features/nytprof-profiling-workflow.md` § What NOT to Do | "Do not assume `nytprofhtml` is in PATH ... always use the full path: <keg path>" | The same warning without the pin, pointing at the resolution mechanism |
| `features/nytprof-profiling-workflow.md` § Quick Start | An opening `cd` to one machine's checkout; five invocations of `extract-profile.pl` through an absolute interpreter path | Repository-relative: no `cd` line, and `perl tests/profile/extract-profile.pl` |
| `features/nytprof-profiling-workflow.md` § Environment tool list | Lists `nytprofcsv` and `nytprofcalls`, invoked nowhere in the repository (§ What NOT to Do already says not to use `nytprofcsv` for subroutine data) | Dropped from the declared tool list (decision 8) |
| `build/generate-cpanfile.sh`, `build/cpanfile` | No profiler declaration of any kind | A fixed development-only block (decision 4) |
| `build/macos-setup.sh` | Installs runtime dependencies only | Installs the development-only phase when asked (decision 5) |
| `README.md` § Developer Setup | No profiler content at all | A profiling subsection (decision 9) |

### Records (not touched)

Each states the Perl a measurement ran under, or is illustrative sample output.

- `tests/profile/results/*/summary.txt`: the Perl version line is generated from the
  profile data itself.
- `tests/profile/results/414-readphase-new/analysis.md` and
  `tests/profile/results/415-statsdrift-new/analysis.md`: name the Perl as the stated
  control of an A/B comparison.
- `tests/profile/results/432-bytes-parity-capture/analysis.md` § Environment note: records
  that the document named one Perl while the toolchain was another, and that the run used
  `--no-html`. This is the prior sighting of this defect and is evidence, not instruction.
- `features/189-histogram-bin-counter-primitives.md`, `features/58-format-registry-staged-detection.md`,
  `features/memory-tracking-improvements.md`, and the `prototype/426-*` reports and result
  files: each attributes a figure to the Perl it was measured on.
- `features/nytprof-profiling-workflow.md` § Example Output: a Perl version inside a fenced
  sample of what the tool prints.
- `tests/validate-statistics.sh` matching a Homebrew prefix as a glob with no version: the
  model for what version-independent matching looks like here, and out of scope.

### Consumers that reference the workflow document but not its paths

`CLAUDE.md` § Where to look, `docs/toolchain-guidance.md`,
`features/418-unsatisfiable-sort-selection-cost.md`, `tests/profile/checks/README.md`,
`tests/profile/checks/consolidation.tsv`, several result `hypothesis.md` and `analysis.md`
files, and `run-profile.sh` itself all cite the document by name and reproduce none of its
paths. A change confined to its Environment, Quick Start and What NOT to Do sections does
not ripple.

---

## Decisions

**D1 (locked by the architect): upgrade safety means Homebrew Perl plus self-install, not
a pinned interpreter.**
The development environment stays Homebrew Perl. No perlbrew, no plenv. After a Perl
upgrade the profiler is restored without the developer having to know anything, because
the profiling run installs it when missing.
*Rationale:* `tests/baseline/README.md` § Same-machine comparability makes the host, and
with it the interpreter, part of what a benchmark number means, and
`.github/workflows/release-build.yml` builds the macOS binary with the same
`build/macos-setup.sh` a developer runs. A separately managed development Perl would
diverge the interpreter that measures from the interpreter that ships. `README.md`
§ Install Dependencies and `CLAUDE.md` § Build both name Homebrew Perl and warn against
macOS system Perl; changing that is a larger decision than this defect warrants.

**D2 (locked by the architect): a missing profiler self-installs; a failed install stops
the run; a missing HTML tool is a stop, never a warning.**
A profiling run whose profiler is missing installs it for the current Homebrew Perl,
printing what it is doing. If the install fails (no network, compile failure) the run
exits non-zero and prints the exact manual command. A profiling run never silently
degrades.
*Rationale:* the capture in `tests/profile/results/432-bytes-parity-capture/` completed
with no HTML report and a `[WARN]` line nobody noticed. A degraded run produces a result
that reads as complete and is not, which is the failure mode that costs the most later.

**D3 (locked by the architect): no mechanism in the repository names a Perl version or a
keg path.**
Records of past measurements are not rewritten; see the sweep above.

**D4 (delegated): the profiler is declared in the cpanfile's development-only phase,
emitted by `build/generate-cpanfile.sh` as a fixed block after the scanned runtime list.**
`build/cpanfile` gains, appended after the sorted scan output:

```
on 'develop' => sub {
    requires 'Devel::NYTProf';
};
```

*Rationale and the properties that make this safe:*

- The generator stays the sole author of the file. Today it scans `ltl` for `use` and
  `require` lines, filters pragmas, and sorts. `ltl` does not load the profiler and must
  not, so no scan can ever emit it; the block is appended unconditionally after the sorted
  list. The file remains fully generated and deterministic: two runs of
  `generate-cpanfile.sh` produce byte-identical output, because the scan output is sorted
  and the appended block is a literal.
- **The default install ignores it.** `cpanm --installdeps` resolves only the `requires`
  phase unless `--with-develop` is passed. Verified in the investigation with
  `cpanm --installdeps --showdeps`, which printed the runtime module only, while
  `--with-develop` printed both. Every build path (`build/install-deps.sh`, the Ubuntu
  Docker block in `build/ubuntu-package.sh`, the CI workflow) calls the default form and
  is therefore unaffected.
- **The packagers cannot pick it up.** `build/macos-package.sh` and
  `build/ubuntu-package.sh` both invoke `pp` with no inclusion flags (no `-M`, no `-a`).
  `pp` decides what to bundle by tracing the script's own dependencies, not by reading the
  cpanfile. `ltl` never loads the profiler, so it is never traced and never packed, even
  on a host where it happens to be installed. This holds because of the flagless `pp`
  invocation, which is true of both packagers today; adding an inclusion flag to either
  would need this restated.

**D5a (delegated): `build/cpanfile.windows` does not carry the develop block.**
*Rationale:* there is no profiling on the Windows path. `build/windows-package.sh` builds
inside a Docker plus Wine container that exists to produce a binary; nothing under
`tests/profile/` is ever invoked there, and the profiler module is an XS build that would
add a compile step for nothing. Keeping the block out of the Windows variant also keeps
the two files' difference exactly what it is documented to be: platform-specific runtime
modules.

**D6 (delegated): `build/macos-setup.sh` installs the development-only phase only when
asked, via an environment variable `LTL_INSTALL_DEV_DEPS=1`.**
The script's dependency step becomes: with the variable set to `1`, run
`cpanm --notest --installdeps --with-develop .`; otherwise the existing
`cpanm --notest --installdeps .`. The script prints which of the two it chose.
*Rationale for an environment variable rather than a command-line flag:* the script takes
no arguments today and has no option parser, so a flag means adding one; the variable is
one conditional. More importantly the caller that must **not** get the profiler is
`.github/workflows/release-build.yml`, which runs `./build/macos-setup.sh` bare as the
macOS build step. A variable that defaults to off means that step is correct without being
edited, and stays correct if the step is ever copied. The developer's documented command
in `README.md` sets it inline, which reads as one command and cannot be half-applied.

**D7 (delegated): tool resolution.**

- **The interpreter is `perl` from PATH.** On a documented setup this is already Homebrew
  Perl, because `build/macos-setup.sh` puts `$(brew --prefix)/opt/perl/bin` ahead of the
  system directories. The preflight asserts it is not macOS system Perl by checking that
  the resolved interpreter path does not begin with `/usr/bin` or `/System/`; on a match
  it stops and names `build/macos-setup.sh` as the remedy. `README.md` § Install
  Dependencies already warns against system Perl, so the check enforces a documented rule
  rather than inventing one.
- **The HTML tool is resolved through the running Perl's own configuration**, by reading
  its script install directory (`perl -V:installsitescript`) and looking for `nytprofhtml`
  there, with `perl -S nytprofhtml` as the PATH fallback.
  *Rationale:* `cpanm` writes scripts into the keg's own `bin`, which Homebrew does not
  link onto PATH, so PATH alone does not find the tool on this machine. Asking the running
  interpreter where it installs scripts is version independent by construction and always
  answers for the interpreter that will actually run, which is the property the pinned path
  failed to have. The `perl -S` fallback covers a setup where scripts do land on PATH (a
  `local::lib`, or a Linux system Perl).
- **No literal path appears anywhere in the resolution.**

**D8 (delegated): the preflight is a separate script, `build/profiling-preflight.sh`,
called from the top of `tests/profile/run-profile.sh`.**
*Rationale for a separate script over an inline sub-step:* the same check is what
`README.md` points a reader at when something is wrong, and what a future consumer
(a benchmark run, or the prototype for issue #528) can call without going through
`run-profile.sh`. A reader who wants to know whether the environment is ready should not
have to run a profiling session to find out. It also keeps `run-profile.sh` about
profiling, and puts environment setup next to the other setup scripts in `build/`, where
`build/setup-hooks.sh` and `build/macos-setup.sh` already live.

**D9 (delegated): the README profiling subsection lives under § Developer Setup, not
beside § Test-harness dependencies.**
*Rationale:* the issue names § Developer Setup as the place the developer's environment is
described, and profiling is development-only, unlike the test-harness Python dependencies,
which sit under § Building from Source because a contributor running the suite needs them.
The subsection is modelled on § Test-harness dependencies in shape (one install command,
the failure it fixes, a verification line, and a pointer onward), not in location.

**D10 (delegated): the Ubuntu Docker path and CI are unchanged.**
*Rationale:* `build/ubuntu-package.sh` creates and destroys a container that installs
system Perl and cpanminus, installs `PAR::Packer`, runs `cpanm --notest --installdeps .`
against `build/cpanfile`, packs the binary and verifies it with `--version`. It produces a
binary and never profiles. The develop phase is opt-in, so the default install it already
runs continues to resolve the same nineteen runtime modules, verified with `--showdeps`.
The macOS CI step is unchanged for the same reason plus the default in decision 6.

**D11 (delegated, smaller): the install the preflight runs is
`cpanm --notest --installdeps --with-develop .` from `build/`, not a bare
`cpanm Devel::NYTProf`.**
*Rationale:* one declaration, one install path. The cpanfile is the single place a
development-only dependency is named, so a second development module added later is picked
up by the same run and the same README command with no further edit. Naming the module on
a command line in a second place would recreate the drift this issue is about.

**D12 (delegated, smaller): a release-notes bullet is written.**
The release notes carry developer-tooling entries: `releases/v0.15.0.md` and
`releases/v0.16.0.md` both describe harness and test-infrastructure changes as user-visible
lines. A profiling workflow that installs its own toolchain and stops instead of degrading
is the same class. One line under Bug Fixes, naming the issue.

**D13 (locked by the architect, 2026-09-13): no automated fixture; testing and validation
are manual during the fix.**
There is no harness for this change. Every acceptance criterion above is exercised by hand
on the development machine while the fix is built, and the completion comment records what
was run and what was observed.
*Rationale:* the failure states require removing a module from the developer's own Perl and
the install needs a network; a harness that creates and restores those states would need the
environment it is testing and is disproportionate to a developer-tooling fix.

---

## Preflight contract

`build/profiling-preflight.sh`

**Inputs**

| Input | Source | Default |
|---|---|---|
| `LTL_PROFILING_INSTALL` | environment | `1` (attempt the install on a miss); `0` means check only and fail on a miss |
| Repository root | derived from the script's own location | n/a |
| The interpreter | `perl` from PATH | n/a |

**Checks, in order**

1. **Interpreter identity.** Resolve `perl` from PATH and read its path. If it begins with
   `/usr/bin` or `/System/`, stop: this is macOS system Perl, which the repository does not
   support.
2. **Profiler module.** `perl -MDevel::NYTProf::Data -e 1`. The data API is the one
   `tests/profile/extract-profile.pl` loads, so checking it checks what is actually used.
3. **HTML tool.** Read the running interpreter's script install directory and look for
   `nytprofhtml` there, executable. If absent, try `perl -S nytprofhtml`. Resolving to a
   path is the pass; the tool is not executed.

**Actions**

- All three checks pass: print the resolved interpreter, the profiler module version, and
  the resolved HTML tool path, exit 0.
- Check 1 fails: no install is attempted. Exit non-zero.
- Check 2 or 3 fails and `LTL_PROFILING_INSTALL` is `1`: print what is being installed and
  why, run `cpanm --notest --installdeps --with-develop .` from `build/`, then **re-run
  checks 2 and 3**. Both pass: exit 0. Either still fails: exit non-zero.
- Check 2 or 3 fails and `LTL_PROFILING_INSTALL` is `0`: exit non-zero without installing.

**Exit codes**

| Code | Meaning |
|---|---|
| 0 | The interpreter is acceptable, the profiler module loads, the HTML tool resolves |
| 1 | System Perl is on PATH |
| 2 | The profiler is missing and the install was not attempted, or was attempted and the re-check still fails |
| 3 | `cpanm` is not available at all |

**Messages**

Each non-zero exit prints one sentence naming what failed and one line the reader can copy.
The copyable line for exit code 2 is the manual command:

```
cd build && cpanm --notest --installdeps --with-develop .
```

For exit code 1 and code 3 it is `./build/macos-setup.sh`. No message names a Perl version
or a keg path; where a path is shown it is one the script resolved at run time.

**Call site**

`tests/profile/run-profile.sh` calls the preflight before it parses its own arguments and
before it creates any output directory, and exits with the preflight's status on a
non-zero. Nothing is written under `tests/profile/results/` when the preflight fails.

**The HTML step in `run-profile.sh`** stops swallowing failure: the invocation is no longer
wrapped in a fallback that prints a warning, and a non-zero exit from the HTML tool fails
the run. `--no-html` remains the documented way to skip the report deliberately, and when it
is passed the preflight's HTML check is not required to pass.

---

## cpanfile shape

`build/cpanfile`, generated end to end:

```
requires 'Devel::Size';
...
requires 'YAML::PP::Schema::YAML1_1';

on 'develop' => sub {
    requires 'Devel::NYTProf';
};
```

The nineteen `requires` lines are the sorted scan of `ltl`, unchanged. The block is a
literal appended after them by `build/generate-cpanfile.sh` for the Unix target only.
`build/cpanfile.windows` is unchanged (decision D5a).

---

## README subsection, proposed verbatim

To be inserted in `README.md` § Developer Setup, after the maintainer-tools paragraph.

> **Profiling tools:** performance work uses `Devel::NYTProf`, which is declared as a
> development-only dependency. Install it once:
>
> ```bash
> LTL_INSTALL_DEV_DEPS=1 ./build/macos-setup.sh
> ```
>
> Run the same command after `brew upgrade perl`. Homebrew installs CPAN modules per Perl
> minor version, inside that version's own directory, so an upgrade leaves your modules
> behind rather than migrating them; nothing is broken, they simply are not visible to the
> new Perl.
>
> Verify the install landed for the Perl that will run the profiler:
>
> ```bash
> perl -MDevel::NYTProf::Data -e 'print "module ok\n"'
> ./build/profiling-preflight.sh
> ```
>
> The first line checks the module. The second also checks that the HTML report tool
> resolves, which is the part that fails quietly: `cpanm` installs scripts into the Perl
> keg's own `bin`, which Homebrew does not put on your PATH.
>
> A profiling run installs the tools itself if they are missing, and stops with the manual
> command if it cannot. See `features/nytprof-profiling-workflow.md` for how to profile.

---

## Surfaces touched

| File | Change |
|---|---|
| `build/generate-cpanfile.sh` | Append the development-only block to the Unix cpanfile |
| `build/cpanfile` | Regenerated, carrying the block |
| `build/macos-setup.sh` | Honour `LTL_INSTALL_DEV_DEPS`; print which install form was chosen |
| `build/profiling-preflight.sh` | New |
| `tests/profile/run-profile.sh` | Call the preflight; resolve the interpreter and HTML tool; stop on HTML failure; repository-relative closing text |
| `tests/profile/extract-profile.pl` | Shebang |
| `features/nytprof-profiling-workflow.md` | Environment, Quick Start, What NOT to Do |
| `README.md` | § Developer Setup gains the profiling subsection |
| `releases/` | One bug-fix line in the open release notes |

Not touched: `build/cpanfile.windows`, `build/install-deps.sh`,
`build/ubuntu-package.sh`, `build/windows-package.sh`,
`.github/workflows/release-build.yml`, `docs/perl-performance-optimization.md` (its
`perl -d:NYTProf` and `nytprofhtml` invocation is the generic form and becomes true once
the tools are installed), `ltl`.

---

## Acceptance criteria

- [ ] **On a machine where the profiler module is missing, `tests/profile/run-profile.sh`
      installs it and completes with an HTML report present.** Observable: after removing
      the module (or on a Perl that never had it), a profiling run prints that it is
      installing, exits 0, and `results/<label>/<sample>/nytprof/index.html` exists.
      *Assertable.* Method: manual, on the development machine, once; the install is a
      network operation and the state to set up is "module absent for the current Perl",
      which cannot be created inside a harness without uninstalling from the developer's
      environment.
- [ ] **With the install made to fail, the run exits non-zero, names the manual command,
      and writes no partial results.** Observable: with `LTL_PROFILING_INSTALL=0` set and
      the module absent, the run exits with code 2, its output contains
      `cpanm --notest --installdeps --with-develop .`, and
      `tests/profile/results/<label>/` does not exist. *Assertable.* Method: the
      environment override in the preflight contract is the specified simulation of a
      failed install; it exercises the same failure branch without needing a network
      outage. Checked by hand alongside the criterion above.
- [ ] **A missing HTML tool stops the run rather than warning.** Observable: with the HTML
      tool unresolvable and `--no-html` not passed, the run exits non-zero before profiling
      and nothing is written under `results/`. *Assertable.* Method: by hand, with the
      preflight's resolution pointed at an empty directory. This is the criterion the
      capture in `tests/profile/results/432-bytes-parity-capture/` would have failed.
- [ ] **No mechanism names a Perl version or a keg path.** Observable:
      `git grep -nE 'Cellar|5\.4[0-9]' -- build/ tests/profile/*.sh tests/profile/*.pl
      README.md` returns nothing, and in `features/nytprof-profiling-workflow.md` the only
      matches are inside the fenced § Example Output block. *Assertable.* Method: the grep
      itself, run at gate time and recorded in the completion comment.
- [ ] **The README verification lines succeed after the documented command.** Observable:
      running `LTL_INSTALL_DEV_DEPS=1 ./build/macos-setup.sh`, then each of the two
      verification lines from the subsection, gives exit 0 from both. *Assertable.* Method:
      by hand on the development machine. The command is the one a reader will copy, so it
      is checked as copied, not as paraphrased.
- [ ] **The macOS release build does not install the profiler.** Observable:
      `./build/macos-setup.sh` run with `LTL_INSTALL_DEV_DEPS` unset prints the default
      install form and not the `--with-develop` form; the CI step invokes the script bare.
      *Assertable* from the script's own flag handling, without running a release build.
      Method: run the script's dependency step with the variable unset and read which form
      it announces. The claim that CI does not set the variable is checked by reading
      `.github/workflows/release-build.yml`, where the macOS step is a bare invocation.
      *Unassertable in full*: that a real GitHub Actions macOS run installs nothing extra
      is not observable from this machine and is not worth a release build to prove; the
      script's behaviour plus the bare invocation is the evidence.
- [ ] **The generated cpanfile is deterministic.** Observable: running
      `./build/generate-cpanfile.sh` twice produces byte-identical `build/cpanfile` and
      `build/cpanfile.windows`, and the second run leaves `git status` clean.
      *Assertable.* Method: two runs and a `cmp` against a copy taken between them.
- [ ] **The default dependency resolution is unchanged.** Observable:
      `cpanm --installdeps --showdeps .` from `build/` lists the same nineteen runtime
      modules and not the profiler; `--with-develop` lists the profiler too. *Assertable.*
      Method: the two `--showdeps` invocations, which resolve without installing. This is
      the criterion that protects the Ubuntu and Windows build paths.
- [ ] **A profiling run on a prepared machine is unchanged in its output shape.**
      Observable: a small run (`--samples 1k`) produces `nytprof.out`, `verbose.txt`,
      `summary.txt`, and the HTML directory, and the summary's cross-validation section
      prints as before. *Assertable.* Method: one 1k run, by hand, compared against the
      shape documented in `features/nytprof-profiling-workflow.md` § Example Output.

**Unknown:** none. Every criterion above has a stated method.

**Verification is manual, by decision (D13).** The criteria are checked by hand on the
development machine during the fix, not by a harness. Profiling is not a validate-`*`.sh
surface, the failure states involve removing a module from the developer's own Perl, and
the install step needs a network.

---

## Completion gate

Per `docs/process/workflow.md` § 3, the diff touches `build/`, `docs`-class documents
(`features/`, `README.md`), `releases/`, and `tests/profile/`, and no executable line of
`ltl`.

**Proposed skip: the full harness suite and the before/after benchmark are both skipped,
with the reason recorded in the completion comment.** The scope table's row "Only
`tests/baseline/`, `build/`, `features/`, `docs/`, `releases/`, `patterns/`, `CLAUDE.md`"
is a skip on both counts. `tests/profile/` is not named in the table, and it is not a
`tests/validate-*.sh` harness, not `tests/lib/`, and not a fixture or expectation any
harness reads: nothing under `tests/profile/` is invoked by the suite, so changing it
cannot change what passing means. Naming the behaviour this change could have altered, per
the checkpoint: it alters what a profiling run does and what `build/macos-setup.sh`
installs, and neither is exercised by any harness or by the benchmark.

**This skip is the architect's to confirm at gate time.**

Checks that still run:

- `./tests/validate-doc-examples.sh` is **unaffected**. Its `DOCS` list is `docs/usage.md`
  only, and its own comment records that README and `CLAUDE.md` carry structural and build
  examples that are out of scope. The README subsection is a build example of exactly that
  kind.
- `./tests/validate-help-content.sh` is **unaffected**: no option is added or changed, and
  `--help` and `docs/usage.md` are not touched.
- The grep criterion above is run and its result quoted in the completion comment.

---

## Ordering

This issue blocks nothing formally. The prototype planned under issue #528 (a transform
that assigns arithmetic into a shared record lexical enlarges every retained duration) is
its first consumer and cannot profile until this is done, but that prototype has other
preparatory work of its own and its plan is not yet fixed, so a hard `blocked_by` edge
would overstate the constraint, and the dependency-first test in `docs/process/issues.md`
§ Blocking relationships answers yes: issue #528 can reach a clean implementation plan
before this lands, it simply cannot run its prototype's measurement. The note above is
therefore informational and is explicitly not a gate.

If the architect decides the edge should be recorded after all, the command is the native
pair from `docs/process/issues.md` § Blocking relationships, with 528 as the dependent and
544 as the blocker. It is not run as part of this specification.

Issue #478 (the highlight decision is re-derived from the `-HL` category suffix throughout
the read loop) is where the gap was found. It is not blocked by this issue: its
investigation already substituted an in-place A/B measurement and proceeded.
