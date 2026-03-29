---
name: Always create feature branch before working
description: ALWAYS create a feature branch before making any code changes, even for investigation/observability work
type: feedback
---

ALWAYS create a feature branch before making any code changes, even for investigation, observability, or debugging work. Never commit directly to a release branch.

**Why:** Violated during #166 — committed observability changes directly to release/0.14.4 instead of creating a 166-* feature branch first. The user had explicitly said "let's work on issue 166" which implies following the standard development process (feature branch → PR → merge).

**How to apply:** When the user says to work on an issue, the FIRST step is always `git checkout -b {issue-number}-{short-description}` from the release branch. No exceptions for "small" changes.
