# Progress Indication Best Practices

How established tools report progress over a set of work items — files to read, copy, download or archive — and what `ltl` adopts from them. Surveyed for #446 (overall progress across all files read); the primary reference for any later progress surface (post-read phases, consolidation, statistics) so the tool's indicators stay consistent.

## The question

A run reads N files of known sizes. One overall percentage must be honest for thousands of 1 KB files *and* for ten 5 GB files. Per-file fixed cost (open, stat, detection sample, first read) dominates the first case; bytes dominate the second. How do tools that face this weight file count against bytes?

## What the industry does

**One dimension owns the percentage; the other is shown beside it, unweighted.** Wherever a byte total is knowable up front, bytes own the number and the file count is a companion counter that never enters it:

| Tool | Percentage | Companion | Source |
|---|---|---|---|
| rsync `--info=progress2` | bytes: (completed files' sizes + current offset) / total size | `(xfr#5, to-chk=169/396)` | `progress.c` `show_progress()` |
| dnf `MultiFileProgressMeter` | `done_size * 100 // total_size` | `(3/42)` prefix | `dnf/cli/progress.py` |
| rclone `--progress` | transferred / total bytes | `Transferred: N / M` | `fs/accounting/stats.go` |
| restic backup | `processed.Bytes / total.Bytes` | `867 files … total 307867 files` | backup progress printer |
| PowerShell `Copy-Item` | `Min(copiedBytes*100/totalBytes, 100)` | "Copied N of M files" activity text | `CopyFileCommand` |
| 7-Zip console | bytes | files counter | console progress |
| curl `--parallel` | `all_dlnow*100/all_dltotal` | `Xfers`/`Live` columns | `src/tool_progress.c` |
| advcpmv (cp/mv patch) | bytes bar | `N of M files copied` | `advcpmv-*.patch` |

Count-based percentages appear only where byte totals are unknown up front and items are roughly uniform — git's object transfer (`Receiving objects: 63% (1234/1960)`, bytes as a throughput suffix only).

### The deviations, and why

| Tool | Approach | Why it deviates | Verdict for `ltl` |
|---|---|---|---|
| APT (`pkgAcquireStatus::Pulse`) | single scalar: `0.8 × bytes% + 0.2 × items%` | item sizes are advisory and sometimes unknown — source comment: "use both files and bytes because bytes can be unreliable" | the only shipped blend; motivated by an unreliable denominator, which `ltl` does not have |
| Windows shell copy (`IFileOperationProgressSink`) | abstract "points": a small file ≈ 2, a large file ≈ 10; points drive the bar, bytes and items are text | prices per-item overhead explicitly | compresses the size axis ~5:1 — the bar would freeze inside one multi-GB file |
| npm `are-we-there-yet` | explicit per-child weights | heterogeneous phases, not files | general, but every weight is an unsourced constant |
| robocopy, Docker pull, pip, wget, sequential curl | no aggregate at all — per-item bars only | — | the negative example: robocopy at scale is run with `/NP /NFL` precisely because a per-file percentage alone is useless |

**No surveyed tool measures per-file overhead.** The only mechanisms in use are APT's implicit equal per-file share and *end-of-item crediting* (dnf credits a file's whole remaining size at `end()`; Docker forces `current = size` on close; rsync adds a file's full length to the numerator at file *start* and subtracts the live remainder).

### The candidate algorithms

| Candidate | Formula | Thousands of tiny files | Ten huge files |
|---|---|---|---|
| Pure bytes | `(Σ completed sizes + current offset) / Σ sizes` | number moves in lumps; the companion file counter carries the sense of progress | exact — the case it is built for |
| Pure count | `(files done + offset/size_current) / N` | smooth | frozen at 10 % steps for minutes; a 100 MB and a 5 GB file weigh the same |
| Fixed per-file cost in byte-equivalents | `work = Σ sizes + N·C`; `done = bytes read + C·files done` | correct only if C is near the true per-file cost; no published value exists (APT's 80/20 ≡ `C = 0.25 × mean file size`) | `N·C` vanishes against Σ sizes — converges on pure bytes |
| Runtime-calibrated C | as above, C re-estimated from elapsed time as files complete | converges only after many files | never converges (few samples) — all the cost, none of the benefit; the denominator moves, so the percentage can go **backwards** |

A moving denominator is treated as a defect by every tool that has one: rsync labels it (`ir-chk` instead of `to-chk` while the list is incomplete), PowerShell clamps it (`Math.Min(…, 100)`), APT clamps with the comment "Wha?! Is not supposed to happen".

## What `ltl` adopts

1. **Bytes own the overall percentage.** Numerator: bytes of completed files plus the live offset (`tell`) of the file in flight. Denominator: the sum of the sizes of every file in the selected list, taken by `stat` once, before the first file is opened. No weighting constant, nothing to calibrate. `ltl`'s position is stronger than any tool surveyed — their totals are provisional (rsync builds its list during transfer, restic scans concurrently, PowerShell pre-scans in a background task); `ltl`'s is exact from t = 0.
2. **A skipped file is credited its full size at the moment it is skipped** — unreadable, empty, filtered, unrecognised. rsync's most-cited complaint is a run ending at 87 % because skipped files sat in the denominator and never entered the numerator.
3. **Clamp at 100** regardless: a log file can grow while it is read, and a future decompressed input would count more bytes than its on-disk size.
4. **A zero denominator renders no percentage** (rclone's `percent()` returns `-` when `total <= 0`); never divide.
5. **Refresh cadence: time-throttled, with a change trigger.** Repaint when ≥ 500 ms have elapsed since the last paint *or* the displayed integer changed — never on a work count alone. rsync gates at 1000 ms, curl `--parallel` at 500 ms, APT at 500 ms, dnf at 300 ms, git ORs a 1 s timer with `percent != last_percent`, rclone at 500 ms. Pure work-based repainting (advcpmv: every 101st read block) is the survey's worst performer on exactly the mixed tiny/huge workload, because the refresh rate then varies with file size and I/O speed. The lesson for `ltl`: a tick every K lines across all files lets an entire small file pass with no repaint.
6. **100 % means done.** A final frame is painted unconditionally outside the throttle (curl: `if (final || diff > 500)`; git `stop_progress()` forces `100% (N/N), done.`; Docker `Close()` sets `current = size`). A percentage below 100 is floored, never rounded, so the figure is never seen before the work it describes is finished. Do not rely on an exact-equality test as the only path to 100 (rsync: `pct = ofs==size ? 100 : …`) — any short read leaves the run parked below it. Replacing the final frame with a one-line completion summary is equally acceptable (APT `Fetched 12.3 MB in 5s`; 7-Zip `Everything is Ok`; `ltl`'s existing `Processing completed.`); leaving the last painted frame short of 100 is not.
7. **Rate and ETA use a trailing window, never whole-run extrapolation.** rsync: 5 × 1 s ring; pv: 30 s ring; dnf: 5 s EMA; APT: 6 s window. advcpmv's `elapsed / done × total` reads visibly wrong on heterogeneous input, which is `ltl`'s normal case. `ltl`'s existing rolling lines/sec sample is already this shape.
8. **Rendering.** One line, `\r`-rewritten, space-padded to erase the previous, longer frame (git computes `clear_len`; rsync pads to the previous length). Truncate the variable part — the file name — with an ellipsis, never the numbers (7-Zip pads the percent to 4 characters and truncates the path). Progress is suppressed for a non-interactive run (git, dnf, rsync's foreground check) — `ltl`'s `--disable-progress`; behavioural notices are never gated behind it, only indicators.
9. **Startup suppression is available if wanted.** git hides its bar for the first second (`GIT_PROGRESS_DELAY`); Nielsen's response-time limits say no indicator is needed under ~1 s and one is required past ~10 s. Not adopted by #446; recorded for a later progress surface.

## Not adopted

- APT's 80/20 blend — a single scalar is approximately wrong in both directions and cannot be audited from the display; the companion counter is the honesty mechanism a blend lacks. If a machine-readable single scalar is ever required, use the fixed per-file cost in byte-equivalents with C measured once on representative hardware and recorded as a locked decision — never the runtime-calibrated variant.
- The Windows points model, for the size compression noted above.
- Per-item-only display (robocopy, Docker) — a known list with known sizes is exactly the position that makes an aggregate honest.

## Sources

- rsync `progress.c` (`show_progress()`, `rprint_progress()`, `end_progress()`), `flist.c` (`stats.total_size`), `receiver.c`/`sender.c` (`total_transferred_size`), `rsync.1.md` `--info=progress2` and the incremental-recursion `ir-chk` note — https://github.com/RsyncProject/rsync
- APT `apt-pkg/acquire.cc` `pkgAcquireStatus::Pulse` (80/20 blend, clamp), `acquire.h` (`PulseInterval` 500000 µs) — https://github.com/Debian/apt
- dnf `dnf/cli/progress.py` `MultiFileProgressMeter` — https://github.com/rpm-software-management/dnf
- git `progress.c` (`display()`, `stop_progress()`, `finish_if_sparse()`, `GIT_PROGRESS_DELAY`), `builtin/index-pack.c` — https://github.com/git/git
- Windows `IFileOperationProgressSink::UpdateProgress` (points example), `IOperationsProgressDialog::UpdateProgress` — https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/
- curl `src/tool_progress.c` — https://github.com/curl/curl
- rclone `fs/accounting/stats.go` `percent()`, `cmd/progress.go` (500 ms) — https://github.com/rclone/rclone
- PowerShell `Copy-Item` progress (`CopyFileCommand`, `Math.Min(…, 100)`) — https://github.com/PowerShell/PowerShell
- advcpmv patch (pre-scan via `find`/`du -s`, KiB truncation, redraw every 101 blocks) — https://github.com/jarun/advcpmv
- pv `pv_calc_total_size()` — https://www.ivarch.com/programs/pv.shtml
- Nielsen, *Response Times: The 3 Important Limits*; Harrison et al., *Rethinking the Progress Bar* (CHI 2007); Conrad et al. on stalled indicators rating worse than none.
