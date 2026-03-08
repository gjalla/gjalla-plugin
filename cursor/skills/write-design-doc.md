# Write Design Doc

Senior and staff engineers at companies like Google, Amazon, Stripe, and Netflix write design
documents before touching code on anything non-trivial. This skill encodes that discipline.

The purpose of a design doc is not bureaucracy — it's thinking. Writing forces you to confront
ambiguity, identify risks, and make decisions explicit before they get buried in implementation
details. It also creates a durable artifact that future engineers (and agents) can reference to
understand *why* things were built a certain way.

---

## Step 0: Load Architecture and Roadmap Context

A design doc is only as good as the understanding that informs it. Before proposing an
architecture, understand what already exists.

**If gjalla is available**, query these tools first:

- `get_context(scope="architecture")` — load the current system architecture so the design
  builds on what exists rather than duplicating or conflicting with it. Identify where the
  proposed change fits in the existing component graph.
- `get_context` — get a comprehensive snapshot of the system. Use `path=` to drill into the
  section most relevant to your design (e.g., `elements`, `connections`, `services`).
- `get_context(scope="rules")` — load ADRs, principles, and invariants that constrain how
  this type of system should be designed. Reference these in your design rationale.
- `get_context(scope="capabilities")` — check proposed/active features to understand what's
  on the roadmap. The design should accommodate planned changes and avoid conflicting with
  in-flight work.
- `get_impact` — for changes to existing systems, analyze the blast radius before committing
  to an approach. A design that touches 40 components has a different risk profile than one
  that touches 3.

**If gjalla is not available**, scan for existing architecture docs, ADR directories, and
planning documents in the repo before starting the design.

---

## When to Write a Design Doc

Write one when any of these are true:

- The work will take more than a few days
- Multiple components or services are affected
- There are meaningful alternatives to consider
- The change affects data models, APIs, or contracts other systems depend on
- You're uncertain about the right approach
- Other teams or stakeholders need to understand or approve the design

Skip it for bug fixes, small refactors, or well-understood changes with a single obvious approach.

---

## Document Structure

Use this structure. Not every section needs to be long — a short design doc is fine if the
problem is straightforward. The goal is completeness of *thinking*, not length.

```
# [Title]: [Brief Description]

## Status
Draft | In Review | Approved | Superseded by [link]

## Context
What's the situation? What problem are we solving and why now? Include relevant background
that a reader needs to understand the motivation. Link to tickets, prior discussions, or
related design docs.

## Goals and Non-Goals
**Goals** — what this design must accomplish. Be specific and measurable where possible.
**Non-goals** — what this design explicitly does NOT try to solve. This is just as important
as goals because it prevents scope creep and makes tradeoffs visible.

## Proposed Design
The core of the document. Describe the solution at the level of detail needed for someone
to review it and for an implementer to build from it. Include:
- System architecture and component interactions
- Data models and schema changes
- API contracts (endpoints, request/response shapes, error codes)
- Key algorithms or business logic
- How this integrates with existing systems

Use diagrams where they clarify relationships. A box-and-arrow diagram of component
interactions is almost always worth including.

## Alternatives Considered
What other approaches did you evaluate? For each, briefly explain what it is and why you
didn't choose it. This is critical — it shows reviewers you've thought broadly and helps
future engineers understand why the current approach was chosen over seemingly obvious
alternatives.

## Risks and Mitigations
What could go wrong? Consider:
- Technical risks (performance, scalability, reliability)
- Operational risks (deployment complexity, monitoring gaps)
- Product risks (user impact, backwards compatibility)
- Security risks (new attack surfaces, data exposure)
For each risk, describe how you plan to mitigate it or why it's acceptable.

## Rollout Plan
How will this be deployed? Consider:
- Phased rollout vs big bang
- Feature flags needed
- Migration steps for existing data
- Rollback strategy if things go wrong
- How you'll know the rollout is successful (metrics, SLOs)

## Open Questions
What haven't you decided yet? What input do you need from reviewers? Being explicit about
what you don't know is a sign of maturity, not weakness.
```

---

## Writing Guidance

**Lead with the "why."** Before describing your solution, make sure the reader understands
the problem deeply enough to evaluate whether your solution actually addresses it. If reviewers
disagree with your approach, it's often because they have a different understanding of the
problem, not because they dislike your solution.

**Be honest about tradeoffs.** Every design has them. Acknowledge what you're giving up and
why the tradeoff is worthwhile. Reviewers trust documents that are candid about limitations
more than documents that present everything as optimal.

**Write for the future reader.** Six months from now, someone (maybe an AI agent) will read
this document to understand why the system works the way it does. Include context that seems
obvious today but won't be obvious later.

**Keep alternatives real.** Don't include strawman alternatives just to make your proposal
look good. If there were genuinely viable alternatives, explain the actual tradeoffs. If the
approach is truly obvious, it's fine to say "no meaningful alternatives were considered" and
explain why.

**Size appropriately.** A design doc for a new microservice might be 3-5 pages. A design doc
for adding a field to an API might be half a page. Match the depth of the document to the
complexity and risk of the change.

---

## Output

Save the design doc as a markdown file in the repository, typically at:
- `docs/design/YYYY-MM-DD-short-title.md`, or
- `docs/rfcs/NNNN-short-title.md`, or
- wherever the project's convention places design docs

If no convention exists, suggest `docs/design/` and note this in the document.

After writing the document, summarize the key decisions and open questions for the user
so they can review efficiently without reading the entire document.

### Attestation: The Design Doc IS the Attestation

The design doc itself serves as the intent declaration for the attestation loop. It declares
what the agent plans to change, why, and what the expected impact is. After implementation,
the design doc can be updated to reflect what actually happened.

```
## Design Doc Attestation

**Architecture context loaded**: [from get_context(scope="architecture") — existing components referenced]
**Rules and constraints respected**: [from get_context(scope="rules") — ADRs/principles that shaped the design]
**Capabilities considered**: [from get_context(scope="capabilities") — existing/proposed features accounted for]
**Predicted blast radius**: [from get_impact — components affected by this design]
**Open architectural questions**: [things that need resolution before implementation]
```

This makes the design doc a first-class artifact in the attestation loop — reviewers can
verify that the design was informed by actual system context, not just the author's memory.
