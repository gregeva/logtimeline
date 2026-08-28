# #445 — An unquoted glob pattern is consumed by the shell before `-r` sees it

Owning doc for the quoting guidance around `-r`/`--recursive`: what the
documentation teaches, and what the tool says when a recursive sweep selects
nothing.

## Requirement

A wildcard pattern written without quotes is expanded — or, in zsh, rejected —
by the shell before `ltl` starts. Two outcomes:

- **Loud.** zsh aborts with `no matches found: access.log_2026-08-*` and `ltl`
  never runs.
- **Quiet, and the dangerous one.** When the pattern does match files in the
  current directory, the shell hands `ltl` a narrowed literal list and the
  recursive sweep covers only that. On the committed fixture tree,
  `-r *.888` selects 2 files where `-r '*.888'` selects 8 — same exit status,
  no warning.

There is no run-time evidence to detect this from: after the shell has run,
what arrives is a list of literal names, which is exactly what a legitimate
`ltl -r access.log` looks like. So no warning can fire on a successful run.

What was asked for, both with zero false-positive risk: every documented `-r`
example teaches the quoted form and says briefly why; and the failure the tool
already prints when nothing matched points at quoting. Shipped release records
carrying the unquoted example are corrected so it stops propagating.

Related: **#420** (recursive file selection) owns the `-r` contract —
`features/420-recursive-file-selection.md`. Its locked decisions cover pattern
splitting, traversal order, symlinks and unreadable directories, and say
nothing about shell interaction. Nothing here changes which files `-r`
selects.

## Decisions

- **D1 — The guidance rides on the existing no-files failure, and nowhere
  else.** The run has already stopped and the tool is already speaking, so
  guidance there costs nothing and can mislead nobody. No new option, no new
  notice, no check on a successful run.

- **D2 — The guidance is conditional on `-r`.** Without `-r`, a pattern the
  shell expanded selects exactly what `ltl` would have selected itself, so
  quoting is not the explanation and the advice would misdirect. The
  `-r`-less failure is unchanged.

- **D3 — The failure carries the guidance as a hint line, not as a longer
  error reason.** `print_usage()` takes an optional third argument, printed
  unbolded on the lines after `Error:` and inside the same error block. The
  `Error: unable to open any files` line is byte-identical to before, so the
  harnesses anchored on it are unaffected.

- **D4 — The "Files" section of `docs/usage.md` says why, not just what.**
  That section already tells the reader glob expansion is internal and does
  not rely on the shell, which is true and is exactly the property an unquoted
  pattern defeats. A reader who stops there concludes quoting is unnecessary,
  so the explanation belongs beside that claim rather than only in the `-r`
  row.

- **D5 — The quoting guidance and the quoted examples are scoped to `-r`, and
  to nothing else.** This is what the issue's "What is wanted" section asks
  for: every documented **`-r`** example teaches the quoted form. The
  non-recursive glob example — `ltl logs/2025-05-*.txt`, in the examples block
  of `print_help()` and in the synopsis of `docs/usage.md` — stays unquoted,
  and so does any other example that does not pass `-r`. Without `-r`, a
  pattern the shell expanded selects exactly the set `ltl` would have selected
  itself, so there is no silent under-selection to guard against; and when the
  pattern matches nothing, both sides fail loudly — zsh refuses the command
  outright, and any shell that passes the pattern through unexpanded leaves
  `ltl` to stop with `Error: unable to open any files`. Quoting is therefore
  not the explanation for anything a reader of those examples can hit, and
  quoting them would teach a remedy for a problem the example does not have.
  Same reasoning as D2 (the failure-message hint fires only under `-r`),
  applied to the documented examples rather than to the failure message.

## What changed, by surface

| Surface | Change |
|---|---|
| `print_help()` in `ltl` | The `-r, --recursive` row quotes both examples and adds the quoting sentence with its reason |
| `docs/usage.md` options row | Same text, same commit (parity gate: `tests/validate-help-content.sh`) |
| `docs/usage.md` § Files | A paragraph beside the internal-glob-expansion claim: what the shell does to an unquoted pattern first, why it does not matter for a single-level pattern, and why it does for `-r` |
| `releases/v0.17.0.md` | The shipped `-r logs/access/*.log` example is now quoted |
| `print_usage()` in `ltl` | Optional hint argument, printed after the `Error:` line |
| The empty-`@in_files` guard in `adapt_to_command_line_options()` | Builds the hint when `-r` is set and hands it to `print_usage()` |

## The failure message

`ltl --disable-progress -ni -r 'no-such-*'` from a directory with no matches
(exit 2):

```
Usage: ltl [-bs <N>] [-n <N>] [-i <regex>] [-e <regex>] [-h <regex>] [-st <time>] [-et <time>]
           [-ov] [-or] [-ru <unit>] [-osum] [-so <field>] [-hm [metric]] [-hg [metric]] <logfile> ...

Error: unable to open any files
Hint: with -r, put the file pattern in double quotes - ltl -r "logs/*.log" - so
      your shell passes it through unchanged. An unquoted pattern is expanded,
      or rejected, by the shell before ltl ever sees it.

Try 'ltl --help' for more information.
```

The same invocation without `-r` prints the identical block with no `Hint:`
line.

## Verification

Scenario `no-match-quoting-guidance` in
`tests/validate-recursive-file-selection.sh`, five assertions:

| Assertion | What it holds to |
|---|---|
| a pattern matching nothing is a hard error (`with-r`, `without-r`) | exit 2 and `unable to open any files` on stderr, unchanged either way |
| the `-r` no-match failure tells the user to quote the pattern | the hint is present |
| the same failure without `-r` carries no quoting guidance | D2 |
| a `-r` run that selected files carries no quoting guidance | D1 — zero false positives |

Invocation shape: the assertion reads a diagnostic emitted while the file
arguments are still being expanded, before a bucket, a table or a `-V` section
exists, so the two runs carry no analysis options at all — the pattern is the
whole input. The successful-run assertion reuses the stderr already captured by
the preceding scenario rather than running `ltl` again.

Each new assertion was proved able to fail (HARNESS-DESIGN.md § "Proving a new
assertion can fail"):

| Sabotage | Assertion that failed |
|---|---|
| Build the hint unconditionally instead of only under `-r` | the same failure without `-r` carries no quoting guidance |
| Never build the hint | the `-r` no-match failure tells the user to quote the pattern |
| Print the hint on the path taken when files *were* selected | a `-r` run that selected files carries no quoting guidance |

Harnesses run on the final content: `validate-recursive-file-selection.sh`
22 passed / 0 failed (17 before this change), `validate-help-content.sh` 11/0,
`validate-help-layout.sh` 6/0, `validate-runtime-config.sh` 36/0,
`validate-doc-examples.sh` 46 passed / 0 failed / 9 skipped.
