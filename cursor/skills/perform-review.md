# Perform Review

Review the implementation through three expert lenses. Output is a unified checklist where
each item is tagged with the persona that raised it: `[TL]`, `[PM]`, or `[QA]`.

---

## Step 0: Load Review Context

A review is only as good as the standards it's measured against. Before reviewing code,
load the team's rules and architecture so you're reviewing against actual expectations,
not generic best practices.

**If gjalla is available**, query these tools first:

- `get_context(scope="rules")` — load ADRs, principles, and invariants. The Tech Lead persona
  should verify that the implementation respects these rules. Any deviation should be flagged.
- `get_context(scope="architecture")` — understand the system architecture so the Tech Lead
  can evaluate whether the implementation fits the existing patterns and component boundaries.
- `get_context(scope="capabilities")` — load the feature's documented capabilities and
  acceptance criteria. The PM persona should verify these are satisfied.
- `get_impact` — understand the blast radius of the changes. The QA persona should verify
  that affected components are tested.

**If gjalla is not available**, review any available design docs, ticket descriptions, and
existing code conventions to establish the review baseline.

---

## Senior Tech Lead

Focus on:

- Code correctness and edge case handling
- Error handling completeness — are errors caught, logged, surfaced appropriately?
- Performance concerns — N+1 queries, unbounded loops, missing pagination, large allocations
- Security — input validation, auth checks, injection risks, secret handling
- Naming clarity and code organization
- Abstraction level — not over- or under-engineered
- Test coverage — are the important paths tested? Do tests verify behavior, not implementation?
- Consistency with existing codebase patterns and conventions

---

## Product Manager

Focus on:

- Does the implementation match the stated requirements / ticket / task description?
- Are there UX or workflow implications that weren't addressed?
- Are error states handled from a user's perspective — clear messages, graceful degradation?
- Is there anything a user would find confusing or broken?
- Are there edge cases in the business logic that weren't covered?
- If there's a UI component, does it handle loading, empty, and error states?

---

## QA Engineer

Focus on:

- Untested code paths
- Boundary conditions — empty inputs, max values, null/undefined
- Race conditions or timing-dependent behaviors
- Test data realism — are tests using trivial/happy-path-only fixtures?
- Integration points — API calls, database queries, external services
- Regression risk — could any change break existing functionality?
- Flaky test patterns — time-dependent, order-dependent, non-deterministic

---

## Output Format

```
## Code Review

### Findings

- [ ] [TL] Missing error handling in `processOrder()` — no catch for network failures
- [x] [PM] Requirements met — all acceptance criteria from ticket #123 addressed
- [ ] [QA] No test for empty cart edge case in checkout flow
- [x] [TL] Good separation of concerns between service and controller layers
- [ ] [QA] Integration test relies on real clock — will flake on slow CI

### Summary

<2-3 sentence overall assessment: what's strong, what needs attention>
```

Items with `[x]` are passing. Items with `[ ]` need attention.

End with a verdict: **Approve**, **Approve with nits**, or **Request changes** — with a count
of blocking vs non-blocking items. This mirrors what a human reviewer would say on a PR.

### Attestation: Review Findings as Attestation

The review findings serve as the attestation for the implementation — they declare whether
the code meets the team's standards and is safe to merge.

```
## Review Attestation

**Rules verified**: [from get_context(scope="rules") — ADRs/principles checked during review]
**Architecture compliance**: [from get_context(scope="architecture") — does the implementation fit?]
**Capability requirements met**: [from get_context(scope="capabilities") — acceptance criteria status]
**Blast radius assessed**: [from get_impact — affected components identified and tested]
**Verdict**: [Approve / Approve with nits / Request changes]
**Blocking findings**: [count and summary]
**Non-blocking findings**: [count and summary]
```
