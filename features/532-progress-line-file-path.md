# Feature: Progress line shows the file's path, shortened in the middle (#532)

## Overview

While logs are being read, the progress line names the file in flight. It has
shown the bare file name, with the directory removed, since the narrow-terminal
display fix (#32). The end-of-run "Processed files" table renders the same file
differently: the path as given, shortened in the middle with an ellipsis when it
does not fit. This drop makes the progress line render the name the way the
table does, so the folder being processed stays visible on the left and the end
of the file name on the right.

## GitHub Issue

#532 — Enhancement: progress line shows the file's path, shortened in the middle like the Processed files table

## Status

In progress (2026-09-04).

## Requirements

- The progress line shows the file's path and name as given on the command
  line or produced by traversal, rendered by the same rule the "Processed
  files" table uses: whole when it fits, otherwise shortened in the middle so
  the start of the path and the end of the file name both remain visible.
- The line's shape is unchanged: the name is still the last element and still
  the one that absorbs the fit (`features/446-overall-progress-indicator.md`
  D5, the filename is the variable-length element that goes last).
- One resolution surface: the existing shortener is reused, not duplicated.

## Locked decisions

**D1 — The progress line calls the shortener the way the "Processed files"
table does: on the path as given, with no directory strip.** The strip was the
only thing that set the two surfaces apart. With it gone the shortener has one
behaviour for both callers, so its strip-path flag is removed rather than left
unused: a flag no caller passes is a second behaviour nobody exercises and
nobody tests.

**D2 — The before/after benchmark runs.** An executable line of `ltl` changed, which is the scope table's first row (`docs/process/workflow.md` § 3); the shortener's own cost is not the point, the rule is. The before run is taken on the base commit in a worktree of the release branch.

## Acceptance criteria

| # | Criterion | Triage |
|---|---|---|
| A1 | With a path that fits, the frame ends with the path exactly as given, directory included | assertable: `tests/validate-progress-line.sh`, scenario `path-in-frame` |
| A2 | With a path that does not fit, the frame ends with the start of the path, an ellipsis, and the end of the file name, and still fits the row | assertable: same scenario, narrow width |
| A3 | The numerics ahead of the name are unaffected | assertable: existing `narrow-terminal` scenario assertions continue to hold |

## Related

- #446 (overall progress indicator) — owns the line's shape; D5 there names the
  filename as the element that absorbs the fit.
- #32 (narrow terminal display fixes) — where the directory strip was introduced.
