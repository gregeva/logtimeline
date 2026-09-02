---
paths:
  - "tests/validate-*.sh"
  - "tests/lib/**"
  - "tests/fixtures/**"
  - "tests/HARNESS-DESIGN.md"
---
# Working on a test harness

Read `tests/HARNESS-DESIGN.md` before creating, renaming, or changing assertion
behaviour in any harness. These are the rules that have cost time when skipped:

- The harness file name tracks the `-V` section it validates, exactly as the
  section is spelled on the CLI; a section rename is a `git mv` in the same commit.
- Every assertion declares `asserts`, `produced_by` (enclosing function name,
  never a line number) and `contract`; all three surface on failure.
- A lookup that matches nothing is a hard failure, never a pass.
- Every harness that invokes `ltl` includes the stderr runtime-warning check
  (`tests/lib/runtime-warnings.sh`); a ` at <file> line <N>` on stderr is a bug.
- Each `ltl` invocation is shaped to the assertion that reads it: smallest
  fixture carrying the signal, everything unread switched off through documented
  options (`docs/usage.md`), `-bs 1440 -oe` for detection and selection checks.
- Committed fixtures are named `.txt`; `*.log` and `*.csv` are gitignored.
  Confirm with `git ls-files` before planning around a fixture.
- While iterating, run only this harness, with `--scenario` or a single-test
  selector; capture the output once and grep the file. The full suite runs once,
  as the completion gate (`docs/process/workflow.md` § 3), and a harness change
  puts that gate in force because what "passing" means has changed.
- Tests are derived from the acceptance criteria in the feature doc, written
  before the code (`docs/test-driven-development.md`). A test written from the
  implementation confirms the implementation, including its misreading.
