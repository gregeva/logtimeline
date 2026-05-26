# ltl : Log Time Line

LogTimeLine (`ltl`) is a command-line log analysis tool that turns timestamped log files into visual timelines. Point it at an access log, application log, or GC log and it aggregates millions of lines into time-bucketed bar graphs, color-coded by severity, with per-bucket occurrence counts, latency statistics, and a ranked summary of the top contributing messages — all on a single screen in seconds.

The core of logtimeline's power is ad-hoc filtering. Include patterns to isolate what matters, exclude patterns to remove noise, and highlight patterns to visually compare a subset against the full population — all using regex, refined iteratively as the investigation evolves. This is something metrics systems fundamentally cannot do: you don't need to pre-define what you want to measure. The question is formed during the analysis, sharpened with each run, and changed direction as you learn. Slice, exclude, narrow, then highlight to see your target in the context of everything else.

The timeline is the anchor. Every feature — heatmaps, histograms, session tracking, thread pool activity, user-defined metrics — is a different lens on the same temporal axis. Start with a week of data in 2-hour buckets to spot anomalies, then zoom to millisecond precision over a 5-minute window to understand exact sequences. Switch from duration to byte analysis, examine percentile distributions, check thread pool saturation — each view reveals a different dimension of the same situation.

Unlike log management platforms, logtimeline works directly on files with no infrastructure, no retention limits, and no query timeouts. Download a single binary, point it at a log, and start investigating. It runs the same on a Linux container, a macOS laptop, or a Windows server. The analysis command line is shown on every run, making investigations reproducible and shareable.

For more on the design philosophy and intended workflow, see [Purpose and Design Philosophy](https://github.com/gregeva/logtimeline/wiki/Purpose-and-Design-Philosophy).

## Getting Started

1. Go to [Releases](https://github.com/gregeva/logtimeline/releases) and select the latest version
2. Download the binary for your platform and architecture
3. Rename the binary to `ltl` and place it somewhere in your `PATH`
4. On macOS, the binary is not signed — you will need to approve execution under **System Settings > Privacy & Security**

```bash
ltl [options] <logfile> [logfile2 ...]
```

## Documentation

See the [Usage Reference](https://github.com/gregeva/logtimeline/wiki) for the full options reference, feature explanations, and examples.

## Screenshots

Here is a very old screenshot showing the tools success in visualizing millions of log lines over a time range in a single screen.

![ltl - very old screenshot](images/slt-30minutewindows.png)

### GC Analysis using Heatmap and Histogram

A Full GC loop explored through zooming in on the specific time range, activating heatmap with 100 character width, enabling duration and bytes histograms, and setting the time-window bucketing to 1 minute.

![Full GC loop explored using heatmap and histogram views](images/gc-log-analysis_full-gc-loop_histogram-and-heatmap.png)

## Building from Source

### Install Dependencies

```bash
# macOS (uses Homebrew Perl — do NOT use macOS system Perl)
./build/macos-setup.sh

# Ubuntu/Linux
sudo apt-get install build-essential perl perl-base perl-modules libperl-dev cpanminus
cpanm PAR::Packer
cd build && ./generate-cpanfile.sh && cpanm --notest --installdeps .
```

#### Test-harness dependencies

The `validate-statistics.sh` harness Layer 3 (external-oracle validation) requires Python 3, NumPy, and SciPy. The harness fails fast with an install hint if any are missing — it does not silently skip Layer 3.

Modern Homebrew Python (macOS) and modern Linux distributions (Ubuntu 24.04+, Debian 12+, Fedora 38+) enforce [PEP 668](https://peps.python.org/pep-0668/), which blocks `pip3 install` against the system-managed Python. The recommended install paths below avoid PEP 668 friction.

Install using `python3 -m pip` (not bare `pip3`). The `python3 -m pip` form guarantees the install targets the same interpreter that `python3` on PATH resolves to. A bare `pip3` can be a sibling binary from a different Python version (e.g. a legacy `python@3.9` brew formula coexisting with the current `python@3.14`), which silently installs the modules into a Python the harness then cannot see.

**macOS (Homebrew Python):**
```bash
brew install python
python3 -m pip install --user numpy scipy
```

**Ubuntu/Linux:**
```bash
sudo apt-get install python3 python3-pip
python3 -m pip install --user numpy scipy
```

`--user` installs packages into your home directory without sudo or system-packages overrides. Verify with `python3 -c "import numpy, scipy"` — if both modules import successfully under the same `python3` the harness invokes, you are done.

Alternative (project-local venv) — useful when you want a fully isolated install:
```bash
python3 -m venv .venv
.venv/bin/python -m pip install numpy scipy
# Then run the harness with the venv's Python on PATH:
PATH=$(pwd)/.venv/bin:$PATH ./tests/validate-statistics.sh
```

If you hit `error: externally-managed-environment`, you are seeing PEP 668. Use `--user` or a venv — do not use `--break-system-packages` unless you understand the consequence.

If `python3 -c "import numpy, scipy"` still fails after install, you have a version-mismatch case: `pip3` (or `python3 -m pip` under an older Python on your PATH) installed into one site-packages directory but the `python3` the harness invokes is a different interpreter. Resolve by re-running the install under the explicit interpreter the harness will use — `which python3` tells you which one that is.

### Build Static Binaries

```bash
./build/macos-package.sh arm64|x86_64    # macOS
./build/ubuntu-package.sh amd64|arm64    # Linux (requires Docker)
./build/windows-package.sh               # Windows (requires Docker + Wine)
```

### Run Directly from Source

```bash
./ltl [options] <logfile>
```

### Developer Setup

After cloning, activate the tracked pre-commit guard once:

```bash
./build/setup-hooks.sh
```

This sets `core.hooksPath` to `.githooks/` and enables `pre-commit`, which blocks accidentally staging Claude Code state (`.claude/`), secret-bearing files (`.env*`, `*.pem`, `*.key`, `id_rsa*`, `.netrc`, `.npmrc`, etc.), and content matching common token patterns. Override with `git commit --no-verify` only when you've verified the match is a false positive.

**Maintainer tools (occasional use):** History hygiene operations require `git-filter-repo`:

```bash
brew install git-filter-repo          # macOS
sudo apt-get install git-filter-repo  # Debian/Ubuntu
```

Not needed for normal development.
