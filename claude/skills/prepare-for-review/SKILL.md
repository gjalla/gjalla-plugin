---
name: prepare-for-review
description: >
  Cleanup and completeness gate to run before task completion in preparation for a code review.
  Use this skill when implementation is done and the code needs to be tidied up before handing off
  to reviewers. Triggers when the user says things like "clean this up for review", "prep for PR",
  "check the definition of done", "remove dead code", "is this complete", "ready to submit", 
  "wrap this up", or when you are nearing completion of a plan.
---

# Prepare for Review

Cleanup and completeness check to run after implementation, before requesting review.
This skill does two things: sweeps for dead code and audits the Definition of Done.

---

## Step 0: Load Definition of Done and Project Rules

Before auditing completeness, load the team's actual standards — not just generic defaults.

**If gjalla is available**, query these tools first:

- `get_context(scope="rules")` — load ADRs, principles, and invariants. These form the
  authoritative Definition of Done. If a rule says "all services must have observability",
  then missing observability is a blocker, not a nice-to-have.
- `get_context(scope="capabilities")` — check if the feature being reviewed has documented
  capability requirements. The implementation should satisfy all documented acceptance criteria.

**If gjalla is not available**, search for a Definition of Done document as described in
Step 2 below.

---

## Step 1: Dead Code Sweep

Scan all files changed in this task (use git diff against the base branch, or the set of files
the user has been working on). For each file, identify:

- **Unused functions/methods/exports** — defined but never called or imported anywhere in the codebase
- **Unused imports** — imported but never referenced in the file
- **Commented-out code blocks** — more than 2 consecutive commented lines that contain code (not documentation comments)
- **TODO/FIXME stubs** — placeholder comments that indicate unfinished work
- **Empty catch/except blocks** — error handling that silently swallows exceptions
- **Unreachable code** — code after unconditional returns, breaks, or throws

For each finding, report the file, line range, category, and recommended action (remove,
implement, or justify keeping).

Don't flag things that look unused locally but are part of a public API or exported interface.
Check for usages across the codebase before flagging. When in doubt, flag it but note the
uncertainty.

After reporting, offer to automatically remove clear-cut dead code (unused imports,
commented-out blocks). Ask before removing anything ambiguous.

---

## Step 2: Definition of Done Audit

Look for a Definition of Done document. Search in this order:

1. Path explicitly provided by the user
2. `DEFINITION_OF_DONE.md` in the repository root or anywhere in the repository
3. A "Definition of Done" section in `CONTRIBUTING.md` or `README.md`
4. Best practices or related guidance provided by developer resources such as gjalla.

If no DoD is found, use this minimal default:

- No placeholder code — all pieces are fully implemented
- No hardcoded credentials or secrets
- No untested code paths on critical flows (cover positive, negative, and edge cases)
- All design decisions are documented
- No known high-criticality bugs

For each DoD criterion, assess pass/fail, for example:

```
## Definition of Done

- [x] No placeholder code — all pieces fully implemented
- [ ] No hardcoded credentials — found API_KEY string in config.ts:14
- [x] All design decisions documented
```

---

## Presenting Results

Group findings by status:

1. **Blockers** — items that must be fixed before requesting review
2. **Passing** — items that are satisfied
3. **Dead code removed** — summary of what was cleaned up

End with a clear verdict: **Ready for review** or **Needs cleanup** with a count of
remaining items.

If there are blockers, offer to fix them. For dead code removal and simple fixes, go ahead
and make the changes (with user confirmation). For larger issues, describe what needs to happen
and let the user decide.

### Attestation: Definition of Done Checklist

The DoD audit is itself an attestation — it declares that the implementation meets (or
doesn't meet) the team's quality bar.

```
## Pre-Review Attestation

**Rules checked**: [from get_context(scope="rules") — which ADRs/principles were verified]
**Capability requirements**: [from get_context(scope="capabilities") — acceptance criteria verified]
**Dead code removed**: [count of items cleaned up]
**DoD status**: [Ready for review / Needs cleanup — with blocker count]
**Blockers remaining**: [list of items that must be fixed before review]
```
