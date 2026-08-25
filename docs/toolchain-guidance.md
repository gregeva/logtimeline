# Toolchain guidance

Environment and tooling traps encountered while working on this repository. Each one here cost a failed, silently-wrong, or misdiagnosed command at least once — they are recorded so the next person (or the next machine) does not rediscover them.

This file is about the *tools used to work on* `ltl` — the shell, `grep`, `perl` one-liners — not about `ltl` itself. Application performance guidance lives in [`perl-performance-optimization.md`](perl-performance-optimization.md); profiling workflow in [`../features/nytprof-profiling-workflow.md`](../features/nytprof-profiling-workflow.md); test-harness rules in [`../tests/HARNESS-DESIGN.md`](../tests/HARNESS-DESIGN.md).

## Shell: the agent toolchain runs zsh, not bash

Development on this repository is frequently driven through an agent shell that runs **zsh** on macOS. Three traps, each of which failed quietly during #312 (2026-07-08):

**1. A bare `=`-leading word is a command lookup.**

```zsh
echo ===LABEL===        # (eval):1: == not found
echo ===                # same
```

zsh resolves a leading `=` word as a command path. Quote it (`echo "==="`) or pick another separator. This bites hardest in ad-hoc progress markers inside long command chains.

**2. `${PIPESTATUS[@]}` is bash-only.**

In zsh the array is lowercase and **1-indexed**: `$pipestatus[1]`. A `${PIPESTATUS[0]}` test written from bash habit expands to empty and the check silently passes. Scripts committed to the repository carry a `#!/usr/bin/env bash` shebang and are unaffected — this applies to ad-hoc commands typed into the agent shell.

**3. Perl `\Q...\E` does not stop variable interpolation.**

```zsh
perl -i -pe 's/\Q$some_regex\E/replacement/' file    # WRONG
```

`\Q...\E` quotes metacharacters in the *interpolated result*; it does not prevent interpolation. If the variable is undefined (it usually is, in a fresh shell), the pattern becomes garbage, nothing matches, the file is unchanged, and **the command exits 0**. A silent no-op reporting success is the worst available failure mode.

For literal in-file replacement, prefer an editor tool with explicit literal matching over a `perl -i -pe` one-liner.

## grep and non-ASCII output

`grep` switches to binary mode when a stream contains non-ASCII bytes, printing `Binary file matches` (or nothing) instead of matching lines. The symptom is a grep returning **nothing** for a line plainly visible in `head`, which reads as "the feature is broken" rather than "the encoding broke the match". This cost hours during #289, grepping captured harness output whose `contract:` / `produced_by:` strings carried `§` and `—`.

Diagnosis: `file <f>` reports "Non-ISO extended-ASCII text"; `od -c | head` shows the bytes; `grep -a` matches immediately.

**Current status:** #291 restricted harness and `-V` output to ASCII, so the routine need for `grep -a` on those surfaces is gone. Reach for it when a grep inexplicably finds nothing, not by default.

The underlying design rule still holds and is enforced by the harness contract: machine-parseable output (`-V` sections, harness diagnostics) is ASCII-only, so consumers never need `-a`. The rendered TUI display (bar graph, box-drawing, block glyphs, ANSI) intentionally uses non-ASCII and is never grepped for assertions — harnesses consume `-V` sections, not rendered output. See [`../tests/HARNESS-DESIGN.md`](../tests/HARNESS-DESIGN.md).

## Running `ltl` from an agent session

Always pass `--disable-progress`. Progress output (spinners, per-file percentages, ETA) is written for a human watching a terminal; in a captured session it is a large volume of redundant tokens. This is separate from the rule that user-facing *informational* messages must never be gated behind that flag — see `CLAUDE.md`.

`--terminal-width N` (hidden option) sets the render width in piped or non-TTY contexts. The `COLUMNS` environment variable does **not** work: `ltl` calls `GetTerminalSize()`, which needs a real TTY. At narrow widths (80–100) omit columns explicitly (`-os -od -ov`) rather than relying on truncation.
