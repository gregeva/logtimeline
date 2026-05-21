# Feature: Packaged-binary smoke-test harness (#227)

## Overview

This document is the **research and scoping deliverable** for issue #227, a sub-task of the [#225](https://github.com/gregeva/logtimeline/issues/225) umbrella for high-priority test-harness coverage gaps. #227 specifically covers smoke-testing the **PAR::Packer-bundled binaries** that the release workflow ships — not the `perl ltl` script that already runs under every other test in `tests/`.

The failure mode this harness targets is: *`pp` succeeds, an artifact lands on disk, the build job exits 0, the GitHub Release attaches the file — and the binary segfaults or aborts on first invocation on a user's machine.* Today the only post-build assertion is `<binary> -version` greps for `[0-9]+\.[0-9]+\.[0-9]+`; that catches gross failures but not the broader class of runtime-only failures listed in §3.

Framework dependency on [#226](https://github.com/gregeva/logtimeline/issues/226) (`-V` section selectivity) is weak. Smoke assertions can be limited to "binary runs, exits with the expected code, stdout is non-empty / contains a stable marker"; they do not require `-V` parsing.

This is **scoping only** — no harness or production code is written here.

## GitHub Issue

[#227](https://github.com/gregeva/logtimeline/issues/227) (sub-task of [#225](https://github.com/gregeva/logtimeline/issues/225); weak dep on [#226](https://github.com/gregeva/logtimeline/issues/226)).

## Sources

- `build/macos-package.sh` (95 lines) — macOS native build.
- `build/ubuntu-package.sh` (102 lines) — Ubuntu Docker build, amd64 + arm64.
- `build/windows-package.sh` (173 lines) — Strawberry Perl under Wine, amd64 only.
- `build/macos-setup.sh` — Homebrew Perl + PAR::Packer setup.
- `build/generate-cpanfile.sh` — `use`/`require` scanner producing `build/cpanfile` and `build/cpanfile.windows`.
- `.github/workflows/release-build.yml` (176 lines) — release pipeline.
- `tests/validate-help-layout.sh` — sibling harness style reference.
- `ltl:64` — `$version_number = "0.14.5"`; `ltl:1856` — `print "Version: $version_number\n\n"` (the literal currently grepped by the build scripts).

## § 1. Build-pipeline inventory

| Build script | Platform / arch | Tool invocation | Output filename | Build host requirements |
|---|---|---|---|---|
| `build/macos-package.sh` | macOS arm64 *or* x86_64 (must match host) | `perl -S pp -o $PACKAGE_NAME ltl` (line 60) | `ltl_static-binary_macos-{arch}` | Homebrew Perl on PATH, PAR::Packer, cpanfile installed. No cross-compile (line 49–57 warns and exits if host arch ≠ target). |
| `build/ubuntu-package.sh` | Linux amd64 *or* arm64 | Inside `ubuntu:20.04` Docker, `--platform=linux/$arch`: `pp -o $PACKAGE_NAME ltl` (line 65) | `ltl_static-binary_ubuntu-{arch}` | Docker / Rancher Desktop; QEMU for arm64 emulation on amd64 hosts. Ubuntu 20.04 chosen for "broad glibc compatibility" (line 20). |
| `build/windows-package.sh` | Windows amd64 only | Inside `ubuntu:20.04` Docker: `wine perl.exe -S pp -o ../$PACKAGE_NAME.exe ../ltl` (line 133) | `ltl_static-binary_windows-amd64.exe` | Docker + Wine + Strawberry Perl portable ZIP (downloaded fresh per run). Windows arm64 explicitly unsupported (line 29–31). |

All three scripts already run a `-version` smoke check inside the build container (`macos-package.sh:79–89`, `ubuntu-package.sh:85–95`, `windows-package.sh:154–166`) and grep for `[0-9]+\.[0-9]+\.[0-9]+`. That check confirms the binary launches at all and emits *a* version line. It does not exercise log parsing, optional code paths, or error handling.

Note: `windows-package.sh` is "best-effort" — its grep failure is downgraded to `[warn]` (line 164) and proceeds, because the Wine-on-CI environment is fragile. This is the single biggest blind spot in the current pipeline.

## § 2. CI workflow inventory

`.github/workflows/release-build.yml` triggers on `push` of any `v*` tag, or `workflow_dispatch`. Four build jobs, then one `release` job:

| Job | Runner | Steps | Artifact uploaded |
|---|---|---|---|
| `build-macos` | `macos-latest` | `macos-setup.sh` → `macos-package.sh arm64` → `./ltl_static-binary_macos-arm64 -version` (line 40) | `ltl_static-binary_macos-arm64` |
| `build-ubuntu` (matrix amd64+arm64) | `ubuntu-latest` | `generate-cpanfile.sh` → `ubuntu-package.sh $arch` → for amd64 `./binary -version`; for arm64 only `file` (line 76–82) | `ltl_static-binary_ubuntu-{arch}` |
| `build-windows` | `ubuntu-latest` | `generate-cpanfile.sh` → `windows-package.sh` (Wine-based `-version` check is internal to script) | `ltl_static-binary_windows-amd64.exe` |
| `release` | `ubuntu-latest`, `needs: [...]`, tag-only | Download all artifacts → flatten into `release/` → `softprops/action-gh-release@v2` attaches them | — |

What is **already asserted** about each binary today:
- macOS arm64: `-version` on the actual runner (line 39–40).
- Ubuntu amd64: `-version` on the actual runner (line 79–81). Ubuntu arm64: only `file` (line 77–78) — no execution because the runner is amd64 and QEMU-emulated execution of a PAR-packed binary is unreliable.
- Windows amd64: `-version` *inside the build Docker container under Wine*, with grep failure downgraded to warning. The artifact itself is **never executed on a real Windows host**.

What is **never asserted** today:
- Heatmap/histogram/percentile code paths exercising modules that `pp` may not have detected statically.
- Error-path exit codes (e.g. nonexistent input file).
- Architecture / format consistency between the artifact and the platform label (the build scripts trust the build host but the upload step does not re-verify).
- Ubuntu arm64 actual execution.
- Windows execution on a real Windows host.

## § 3. PAR::Packer failure modes

These are the classes of "build succeeds but binary fails" that a smoke harness can plausibly catch. Drawn from PAR::Packer issue tracker, project `build_notes`, and direct experience with this codebase.

| Class | Cause | Detection cost |
|---|---|---|
| **Missing bundled module** | `pp`'s static `Module::ScanDeps` misses a runtime-only `require` (common with `eval "require ..."` or dynamic class loading). Reproduced historically with `Win32::API`, `PDL::*` (per `build/packaging-notes:53–67`). | A single full-flow invocation against a small log catches almost all of these. |
| **Architecture mismatch** | arm64 binary handed to an x86_64 user, or vice-versa. macOS would refuse with "Bad CPU type"; Linux with `Exec format error`. | A simple `file` check + `-version` execution on the matching arch covers this. |
| **glibc / libc version mismatch** | Binary built on newer Linux (glibc 2.39) fails on user's older Linux (glibc 2.31) with `version 'GLIBC_2.34' not found`. Ubuntu-20.04-as-build-base (line 20) is the existing mitigation. | Detected only by running on the *oldest supported* target. Beyond pure smoke; flag as a separate concern (see §11 open questions). |
| **Inline::C cache pollution** | Stray `_Inline/` directory carried into the PAR archive causes `pp` to bundle stale compiled `.so` files. Per `MEMORY.md`, `_Inline/` is now `.gitignored`. The prototype's `--inline-c` path is opt-in, so production `ltl` should not embed compiled C — but a regression here would slip past `pp`. | A clean checkout in CI normally avoids this. Local-iteration story (§10) must spell out: never copy `_Inline/` into the `pp` working directory. |
| **Encoding / locale dependency** | `Encode::*` sub-modules not bundled, surfacing only on non-ASCII input or unset `LC_ALL`. | The Windchill Apache fixture contains UTF-8 paths and would catch this. |
| **Missing shared library** | `Term::ReadKey`, `Proc::ProcessTable`, etc. link against system `.so` files that PAR cannot bundle. On a stripped-down user host (alpine, BusyBox) the binary aborts. | Out of scope for in-repo smoke (no minimal-base CI runner today). Note in §11. |
| **`Cwd::abs_path` / `__FILE__` resolution** | PAR rewrites `$0` to a temp extraction path; code that does `dirname(__FILE__) . "/patterns/"` finds nothing. ltl reads pattern files via `-if/-ef/-hf`, so this is a *user-data* concern, not a packaging one — but worth a one-line probe. | A `-ef patterns/probes <log>` invocation would catch it. |
| **Wine-only artifact divergence** | The Windows binary is *built under Wine*. Wine's Perl behaves; native Windows Perl may differ on path-separator and `binmode` edge cases. | Only catchable by running on a real Windows runner (`windows-latest`). |

## § 4. Minimum-viable smoke assertions

Ranked by signal-per-second:

1. **`<binary> --help` → exit 0, stdout contains `ltl` and `Usage:`.** Cheapest; catches "binary won't launch at all" and "help renderer crashed". Already partially exercised by `tests/validate-help-layout.sh`, but only against the Perl script.
2. **`<binary> -v` (or `--version`) → exit 0, stdout matches `^Version: \d+\.\d+\.\d+`.** Already done; keep.
3. **`<binary> --disable-progress <tiny-log>` → exit 0, stdout non-empty, contains the standard banner `,:: ltl ::'`.** This is the smallest end-to-end invocation that exercises file open, regex compile, and bar-graph render. Catches the largest set of "missing module" cases.
4. **`<binary> --disable-progress -hm duration <tiny-log>` → exit 0, stdout non-empty.** Exercises the heatmap code path, which uses different modules than the default bar graph. Cheap insurance against `pp` missing an optional dependency.
5. **`<binary> /nonexistent-file 2>&1` → exit non-zero.** Negative-case; see §9.

Stretch (skip for v1):
- `-hg latency` (histogram) — overlaps heatmap, marginal additional coverage.
- `-V <tiny-log>` — depends on #226 stabilising the section format; not required.

**Recommended v1 set: assertions 1, 2, 3, 5.** Assertion 4 is *recommended* but acknowledged as overlapping with 3 once #226 is in; defer to "post-#226" if budget pressure.

## § 5. Test-log fixture

Candidates and trade-offs:

| Candidate | Size | Issue |
|---|---|---|
| `logs/AccessLogs/localhost_access_log.2025-03-21.txt` | 2.6 MB | **Do not use** — MEMORY.md flags corruption (`feedback_test_logs.md`). |
| `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` | 83 KB (741 lines) | Smallest clean access log in the repo. Real-world data; exercises Tomcat access-log parser. |
| `logs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` | larger | Already used elsewhere as a "known-good" fixture; overkill for smoke. |
| New `tests/smoke-fixtures/binary-smoke.log` | hand-crafted, ~10 lines | Deterministic, minimal, easy to diff. But synthetic — risk of not matching any real log format ltl supports. |

**Recommendation: a new hand-crafted fixture at `tests/smoke-fixtures/binary-smoke.log` (~10 lines, Tomcat access format with millisecond durations).** Rationale: (a) deterministic output is essential when the harness greps stdout, (b) it should not change when an unrelated `logs/` file is re-organised, (c) it should be small enough that any noticeable change in execution time signals a real problem, (d) the Codebeamer file is 741 lines and would still produce ~100ms of output to grep through. Synthesise it once, commit it, never touch it.

Output assertion against this fixture is the *banner*, not statistics — keeping the harness immune to format changes.

## § 6. CI integration design

Three options:

| Option | Shape | Pros | Cons |
|---|---|---|---|
| **(a) Per-platform inline** | Add a `Smoke test` step to each `build-*` job, before `Upload artifact`. | Fails fast; the failing job's logs explain which platform broke. Minimal new infra. | Duplicate harness wiring across four jobs (mitigated by a shared script). |
| **(b) Unified post-build job** | New `smoke` job, `needs: [build-macos, build-ubuntu, build-windows]`, downloads all artifacts, runs harness inside a matrix of runners (macos-latest, ubuntu-latest, ubuntu-24.04, windows-latest). | Tests on the *intended user runtime*, not the build host. Catches the Wine-vs-native-Windows class. Single harness invocation. | Adds ~3 min to release; another job to debug if it fails. |
| **(c) Both** | Inline per-platform sanity (a) + unified parity (b). | Belt-and-suspenders. | Doubles smoke runtime; mostly redundant. |

**Recommendation: (b) unified post-build job, with a `windows-latest` runner specifically to validate the Wine-built `.exe` on real Windows.** Rationale: the Ubuntu arm64 and Windows artifacts today are *not actually executed on their target platforms anywhere in CI* (§2). A unified post-build job is the smallest change that closes both gaps. The existing inline `-version` checks in the build scripts can stay as a fast-fail filter; they already are.

The new job matrix should include at minimum: `{os: macos-latest, artifact: macos-arm64}`, `{os: ubuntu-latest, artifact: ubuntu-amd64}`, `{os: windows-latest, artifact: windows-amd64.exe}`. Ubuntu arm64 actual execution is harder (no native arm64 runner on free tier) — defer with an explicit `file`-only check, same as today.

## § 7. Cross-platform mechanics

The harness must handle three target runtimes:

- **macOS arm64** — bash, native shell-out fine. Use `bash`.
- **Linux amd64** — bash, native. Use `bash`.
- **Windows amd64** — `windows-latest` GitHub runner ships Git Bash, PowerShell, and `pwsh`. PAR-packed `ltl_static-binary_windows-amd64.exe` is a self-extracting exe; it runs from any of them. Path separator is `\`; `--disable-progress -- <log>` argument passing is unaffected.

**Recommendation: bash harness, invoked via Git Bash on Windows (`shell: bash` in GitHub Actions).** Git Bash is preinstalled on `windows-latest`. This keeps one harness script. Alternatives considered:
- *PowerShell + bash twins*: doubles maintenance. Rejected.
- *Perl driver*: would need Perl installed on the smoke runner; the whole point is that the user does not have Perl. Rejected.

Caveats for Windows specifically:
- Capture exit code via `$?` after the command, not via `;` chaining (cmd.exe semantics leak through some Git Bash builds).
- Use forward slashes in paths — Git Bash translates.
- Expect the `.exe` extension; the artifact filename already includes it.

## § 8. Failure-handling story

When a platform's smoke fails:

| Posture | Behaviour | Recommendation |
|---|---|---|
| Block entire release | Any smoke failure → `release` job does not run → no Release attached. | **Yes, default.** Shipping a known-broken binary to users is worse than a delayed release. |
| Per-platform partial-release | Failing platform's artifact omitted from the GitHub Release; others ship. | Tempting but adds complexity; the `softprops/action-gh-release@v2` step would need conditional `files:` patterns. Users on the omitted platform have no signal that they should wait. Reject for v1. |
| Warn-and-decide | Smoke job records failure but does not block. Human reviews and re-runs / overrides. | Useful as a *transient* posture during initial rollout, when the harness might have false positives. Implement as a `continue-on-error: true` toggle that defaults to `false`. |

**Recommendation: block by default, with a `workflow_dispatch` input `allow-smoke-failure` for emergency overrides.** This keeps the safe default while leaving an audited bypass.

## § 9. Negative tests

`<binary> /nonexistent-file 2>&1; echo $?` asserts exit code is non-zero.

Why bother: catches the failure mode where `pp` packaging mangles `die` handlers such that the binary silently exits 0 on a missing input. This has happened with PAR-packed Perl in the wild (truncated stderr, exit code reset by the PAR loader stub). It is cheap to add — one extra invocation.

**Recommendation: include.** Worst case it asserts the obvious; best case it catches a class of regression that nothing else will. Pair it with a stdout check (`grep -i "no such file\|cannot open"`) for slightly stronger signal — but exit-code-only is sufficient for v1.

## § 10. Local-iteration story

A developer mid-investigation needs the same harness against a binary they just rebuilt:

```
./build/macos-package.sh arm64
tests/validate-binary-smoke.sh ./ltl_static-binary_macos-arm64
```

The harness must:
1. Take the binary path as `$1` (so the same script serves CI and local).
2. Auto-detect platform from `uname` only when `$1` is omitted; otherwise trust `$1`.
3. Look up the smoke fixture relative to `$0` (the harness path), not `$PWD`.
4. Print pass/fail counts and exit non-zero on any fail.

CI invocation is then just `tests/validate-binary-smoke.sh artifacts/ltl_static-binary_${os}-${arch}`.

**Recommendation: single-script reuse, no separate CI/local entry points.** Mirrors the pattern of `tests/validate-help-layout.sh`.

## § 11. Application-observability gaps

Reviewed for completeness; mostly empty.

| Possible addition | Recommendation |
|---|---|
| `-V version` section emitting `version<TAB>0.14.5` | Already exists at `ltl:7419` inside `=== BENCHMARK DATA ===`. Sufficient. `225-help-content.md §6a` reached the same conclusion. Do not duplicate. |
| `--smoke` mode running internal self-checks | Overkill. The smoke surface is "does it run at all", which is observable by *running it*. Reject. |
| Banner-line stable marker (`,:: ltl ::'` at `ltl:1571`) | Already stable; harness can grep it. No code change. |
| Stable error-marker on file-not-found | Not currently grep-asserted; if §9 negative test wants a stdout pattern, the existing `die` message suffices. No change. |

## § 12. ltl code changes required

**None.** The harness is purely external observation. The existing `-v`, `-version`, `--help`, and banner output give the harness everything it needs.

Optional (zero-cost, non-blocking): co-locate the smoke fixture at `tests/smoke-fixtures/binary-smoke.log` so the path is stable across release branches.

## § 13. Harness-shape proposal

**Filename**: `tests/validate-binary-smoke.sh`.

**Usage**:
```
tests/validate-binary-smoke.sh [<path-to-binary>]
```
Default `$1`: auto-detect (`./ltl_static-binary_$(uname -s)-$(uname -m)`).

**Outline** (no implementation):

1. Resolve binary path; assert existence and executable bit.
2. Resolve fixture path (`$SCRIPT_DIR/smoke-fixtures/binary-smoke.log`); assert exists.
3. Assertion A: `<binary> --help` exits 0, stdout contains `Usage:` and `ltl`.
4. Assertion B: `<binary> -v` exits 0, stdout matches `^Version: \d+\.\d+\.\d+`.
5. Assertion C: `<binary> --disable-progress <fixture>` exits 0, stdout contains banner marker `,:: ltl ::'`.
6. Assertion D: `<binary> --disable-progress -hm duration <fixture>` exits 0, stdout non-empty. *(optional v1)*
7. Assertion E (negative): `<binary> /nonexistent-file-xyz` exits non-zero.
8. Print `PASS N / N` summary; exit 0 iff all pass.

**Cross-platform notes**: pure POSIX-friendly bash; no GNU-only flags. Use `command -v file` defensively (Git Bash may not have `file`). Wrap binary invocations with explicit `2>&1` so Windows stderr funnels into the captured stdout.

**CI wiring** (`.github/workflows/release-build.yml`):

```yaml
smoke:
  needs: [build-macos, build-ubuntu, build-windows]
  strategy:
    matrix:
      include:
        - {os: macos-latest, artifact: ltl_static-binary_macos-arm64}
        - {os: ubuntu-latest, artifact: ltl_static-binary_ubuntu-amd64}
        - {os: windows-latest, artifact: ltl_static-binary_windows-amd64.exe}
  runs-on: ${{ matrix.os }}
  steps:
    - uses: actions/checkout@v4
    - uses: actions/download-artifact@v4
      with: {name: '${{ matrix.artifact }}', path: .}
    - shell: bash
      run: |
        chmod +x ${{ matrix.artifact }} || true
        ./tests/validate-binary-smoke.sh ./${{ matrix.artifact }}
```

Then update `release` job's `needs:` to include `smoke`.

## § 14. Open questions for human review

1. **Ubuntu arm64 actual execution** — GitHub Actions has no free-tier native arm64 Linux runner. Options: (a) accept the `file`-only check we already have; (b) self-hosted runner; (c) QEMU emulation in CI. Recommend (a) for v1; revisit after the harness lands.
2. **Smoke-fixture format** — synthesise a 10-line Tomcat access log? Or include both an access log and a Java-style application log to exercise both timestamp regexes? Single fixture keeps the harness simple; two doubles surface coverage. Recommend one to start, add second only if a failure escapes that the second would have caught.
3. **Windows native vs. Wine parity** — should the harness compare *stdout byte-for-byte* between Wine-built `.exe` running under Wine in build and the same `.exe` running on `windows-latest`? Tempting but brittle. Recommend: same assertion set, not byte-diff.
4. **Block-vs-warn on smoke failure** — confirm §8 recommendation (block by default) is acceptable.
5. **glibc compatibility check** — the harness as scoped runs on the *latest* `ubuntu-latest` runner, which has the newest glibc. The old-glibc protection lives entirely in `ubuntu:20.04` as the build base. Worth adding a separate `ubuntu-22.04` or container-based smoke step to catch glibc regressions? Defer; raise as a follow-up issue if it ever bites.
6. **Negative-test stdout grep** (§9) — exit-code-only, or also assert stderr contains "no such file"? Recommend exit-code-only for v1.

## § 15. Effort estimate

**Overall: LOW–MEDIUM.**

| Component | Effort |
|---|---|
| `tests/smoke-fixtures/binary-smoke.log` (hand-crafted ~10 lines) | 30 min |
| `tests/validate-binary-smoke.sh` implementation | 2–3 h |
| `.github/workflows/release-build.yml` smoke job (matrix + wiring) | 1 h |
| First-run CI debugging (cross-platform path quirks, Windows-specific) | 1–2 h |
| Documentation (one paragraph in `build/build_notes` or README, optional) | 15 min |
| **Total** | **~half-day to one full day** |

No prototypes or experiments needed. The risk is concentrated in (a) Windows path handling in Git Bash and (b) Wine-built `.exe` behaviour on real Windows — both deferred to first-run debugging.
