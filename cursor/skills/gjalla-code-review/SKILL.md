---
name: gjalla-code-review
description: Review a code change (diff or PR) for ship-readiness before merge. Use when reviewing your own or someone else's changes prior to committing/merging/etc.
---

# Code Review

Your task is to review the code changes as a team lead with extremely high standards.
You care about: simple, elegantly-designed, maintainable code; code which meets the expectations and verification criteria; code which is well-tested, robust, secure, and production-ready; and code that balances everything you know about the end user, the company, and the feature.

## Approach
1. Goal versus reality. Answer three questions in order, before reading the diff for defects: **what was the goal** (from the PR description, linked spec, or commit messages, in one sentence)? **What mechanism did we actually build?** **Do those two close the same gap, and did we do it sanely and safely?** A change can be clean, tested, well-factored, and still not be the thing that was asked for.
2. Put yourself in the shoes of multi-faceted reviewers based on what is relevant to this change. For instance, the perspective of a senior software engineer who is skilled at code correctness / dead code / DRY adherence; an architect who looks for spaghetti code, elegant designs that are minimal yet effective, code that lives up to architectural best practices and gets cleaner over time; a product manager who is great at user experience, voice of the user, and auditing workflows for confusion, duplication, and incompleteness; a QA engineer looking for quality, bugs, edge cases, and maintainability; a customer success manager responsible for implementation and value delivery; or a security analyst looking for data access / privacy / security / vulnerabilities.
Each review must include the perspective of the architect and the security analyst. Otherwise, no need to a) use all of these personas or b) use only these personas. Use the context of the change to determine what the most helpful, adversarial, and gap-filling approach would be and take it.
3. From each perspective, review the diff in full, using second order thinking (what collateral, implicit, or second-order implications do these changes have?) and fresh eyes. The quality lenses that always apply: is it minimal, elegant, effective, not overengineered, and maintainable?
4. Based on what you've found, what is the priority of these items within the context of this user/product/company?

## Review until clean

A review with findings is not the end of the process — it's the middle. A non-clean review mandates another full round with fresh eyes after the fixes land, until a round comes back clean (no blocking or must-fix changes; cap at 5 rounds).

- "Fresh eyes" is literal: where your agent supports subagents, spawn a fresh-context reviewer for each round rather than re-reading your own work — self-review after self-fix is grading your own homework. Where you can't, disclose it: add `--evidence review_mode=self` to the marks below.
- Keep a short record of each round in your working notes: what was found, what changed, and whether the round came back clean.

- If you hit the cap without a clean round, do not loop forever and do not quietly proceed: record the final round honestly and surface the unresolved findings to the human.

## Output
Group findings by severity:
- **Blocking** — must fix before merge (correctness, security, data loss).
- **Should fix** — quality/maintainability issues worth addressing now.
- **Nit** — optional polish.

For each finding: `file:line`, what's wrong, and a concrete suggested fix. State what you verified and what you could not.

## Principles
- Review the code that's there AND what's missing — the dangerous bug is usually the unhandled case, not the wrong line.
- Be specific: a finding without a location and a fix is noise.
- Approve only what you understand. If you can't tell whether it's correct, say so rather than rubber-stamping.
- Verify before reporting conclusions. When you think you have found a defect, double check the source, data flow, etc to bolster your understanding before jumping to conclusions.
- You may be reviewing partial implementations toward a goal. That's fine, sometimes users and agents work incrementally. Make sure to note it in your report, but it could be intentional and therefore not fatal.
- Check that what you're reading is current before you reason about it. A stale checkout, a leftover worktree, or a cached artifact will produce a confident and wrong review.
