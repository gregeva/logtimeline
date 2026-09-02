---
paths:
  - "docs/usage.md"
  - "docs/explain/**"
  - "README.md"
---
# User-facing documentation

These files describe what the user observes and what it means to them. They
are copied verbatim to the public wiki at every release.

- No internals: no Perl identifiers, sub or hash names, issue numbers, decision
  labels, harness names, or other tools' internals unless operationally useful
  to the reader.
- `docs/usage.md` and `print_help()` in `ltl` document the same options and
  are edited together in the same commit; descriptions stay consistent, not
  necessarily identical.
- Examples must run: `tests/validate-doc-examples.sh` executes them.
- No customer-identifying data, hostnames or provenance in sample lines;
  placeholders only.
