---
paths:
  - "prototype/**"
---
# Prototypes

A prototype answers a question before implementation commits to an answer.
`prototype/README.md` is the rule; these are the parts that have failed:

- The baseline arm reproduces the production code path verbatim, including
  call shape, variable scoping and data movement. A convenience wrapper around
  the logic measures the wrapper, not the candidate.
- Every constant is sliced out of `ltl` (pattern:
  `prototype/459-order-independence/extract-subs.sh`); where one must be
  restated, the source symbol is named in a comment beside it.
- Scale is staged (1k, 10k, 100k, millions); results are medians with ranges.
- The exit is a decision recorded as Dxx in the owning feature doc, or for a
  verification-method prototype, a demonstrated assertion that distinguishes
  known-good from known-bad input, proposed with its cost.
