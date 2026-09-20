---
name: gjalla-spec-review
description: Full review of a plan or spec to be sure there are no surprises, gaps, or mistakes. Use to harden a spec before implementation.
---

# Comprehensive spec-review

The best, most elegant and effective software systems are ones that are well-informed, well-planned, and verifiable. 
The final output is a plan/spec that can act as a reference doc, covering the problem/motivation, technical approach, deltas (what properties of the system will change once implemented), and verification criteria.

Your task is to review this spec from multiple expert perspectives to ensure that this spec meets our expectations and will result in solid implementations once it's in the hands of the engineers.

The bar: the design should be elegant, well-designed, minimal, maintainable, and not overengineered — something the team would be proud to ship. A spec that merely works but fails that bar is not done.

## Efficacy Review
Run this one first. Every other lens checks that the thing being built is well-formed; this is the only one that checks it is the same thing as the stated problem.
- Restate the goal, then restate the mechanism. Do they close the same gap?
- For any goal about preventing something: what is the cheapest way to get the bad outcome anyway? Trace the path a hostile or indifferent user takes. **If that path doesn't run through the changed code, the goal may not be met**, no matter how good the change is.
- Which layer enforces it? A control in the client is a suggestion.
- Is the spec solving the problem, or solving the first solution someone proposed for it?

## Architect Review (reference the gjalla master spec where needed)
- Does the design fit the existing system and respect layer boundaries?
- Are new components placed in the correct layer and ownership hierarchy?
- Is it compatible with the broader system (i.e. cross repository integrations, future goals, etc.?)
- Is it overengineered or introducing complication that will be difficult to understand/maintain? Make this a concrete test rather than a judgment call: is any part of this dead code until some *other* change ships? If so, cut it now and note it as a follow-up. Same for a knob nobody has asked to turn, or an abstraction that is overcomplicated. The goal is elegant, well-designed solutions that are effective and even result in a cleaner, more intuitive codebase over time.
- Do new commands, endpoints, files, or concepts share a trigger, data source, and output channel with something that already exists? Are established patterns followed and existing code/tools reused?

## Security Review & Threat Model
Threat modeling is part of the spec, not a later gate. Note that the questions below are deliberately not scoped to the diff: the dangerous vulnerability is usually reachable through code this change never touches.
- Who is the adversary here, and what are they after? Consider at least: an indifferent user taking the cheapest path, a hostile user, a compromised or curious teammate, and another tenant.
- For each, trace the shortest path to the outcome you don't want. What stops them, and where does that control live?
- What becomes reachable that wasn't before — new data to new consumers, a new trust boundary crossed, a surface newly exposed to the internet?
- Do the changes respect data security and privacy boundaries, such as including authentication and authorization on all new endpoints, and ensuring no cross-user/cross-tenant data leakage?
- Does the data model handle sensitive data correctly (PII, secrets)?
- Are inputs validated at the surface-area boundary?
- How would we know if this were being abused? What would show up, and where?

## Quality Review
- Is the testing strategy sufficient for the behavioral requirements?
- The goal for AI-generated code is typically 100% test coverage, are positive, negative, edge, and secure coding cases covered? Are appropriate and effective integration tests scope based on the end-goals?
- Do acceptance criteria map to testable assertions?

## User Experience Advocate Review
- Does the feature solve the stated problem?
- Are failure modes graceful from the user's perspective?
- Is the feature discoverable and documented?

## Governance Review
- Does the spec comply with all active project rules and conventions? (stored in gjalla - check there if needed)
- Are any rule exceptions or approvals needed?
- Does this change warrant an architecture decision record (ADR)? (most do not, but ones that introduce significant, new tradeoffs may)

## Output
For each perspective, report: what passes, what's at risk, and concrete changes required before implementation. Separate **blocking** concerns from **recommendations**.
