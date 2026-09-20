---
name: gjalla-spec
description: Create a well-thought-out plan covering problem statement, goals, technical approach, and verification criteria. Use while planning / before implementing any non-trivial feature.
---

# Goal

The best, most elegant and effective software systems are ones that are well-informed, well-planned, and verifiable. 
The final output is a plan/spec that can act as a reference doc, covering the problem/motivation, technical approach, deltas (what properties of the system will change once implemented), and verification criteria.
The first step is always understanding the current state. Use gjalla (CLI or MCP) to fetch the relevant parts of the master spec, including the architecture, capabilities, data flows, etc that are relevant to this problem/solution space. Also fetch the gjalla rules so you know what boundaries there are on your final solution.
Once you understand the relevant properties and constraints, identify any specific details that you need from the source code and gather them.
Now you have everything you can find yourself. Are there any outstanding questions that will affect the specifics of the solution you propose? If so, ask the user for input.

When you have everything you need, go ahead and use `gjalla spec new` which will scaffold a change spec for you to edit. This is necessary for workflows where spec artifacts are canonical, and the gjalla platform will facilitate verifying and merging changes into the master spec once implementation is complete.
Think through the end-goal, the context (architecture, data flows, use case, etc.) and your rules/constraints, then work to design an elegant, maintainable, effective solution to the goal.

The information needed for a production-grade spec / reference doc includes the following:
- **Problem Statement**: What user or system problem does this solve?
- **Goals**: What must be true when this is done?
- **Non-Goals**: What is explicitly out of scope?
- **Behavioral Requirements**: Observable behaviors the feature must exhibit, in other words, new capability properties that will be present within the system. For any requirement about what the system permits or prevents, state it as system state rather than as something the user sees, and name the file and function that enforces it. A requirement no code location owns is a wish.
- **Threat model and security requirements**: What are the adversarial security cases we have considered with this design? What properties of secure software systems need to be built into the solution and have associated tests to ensure we never regress?
- **Technical Approach**: How will this be built? How will this affect architecture, data flows, surface area, and other gjalla primitives?
- **Verification Strategy**: Unit and integration tests for positive/negative/edge cases are a given; you should also consider security & safety (i.e. do our tests include common secure coding pitfalls like the AI OWASP Top 10 or tests for other security mistakes that could make us vulnerable?), maintainability, performance, user experience, or domain-specific verification criteria such as compliance, business constraints, or platform constraints. Name at least one test that fails today and passes once this is built — if you can't name one, the goal isn't yet concrete enough to implement against.
- **Dependencies**: What must exist or be deployed first? Consult gjalla if your project is a part of a system and this may affect its interoperability.
- **Rollback Plan**: How to safely revert if something goes wrong.

## Guidelines

- Specs and plans are not novels. Background information and context is totally acceptable (in fact its preferred) as long as the information is clear, salient, relevant, and not overly verbose.
- The goal is to get ahead of unintended consequences. Use second order thinking to get ahead of potential surprises.

## Present and bind

Once you're happy with the solution you've written into the spec, it should be presented to the human for approval — this is the first of two human gates in the gjalla-autonomous process (the other is at commit). Use your native plan-presentation mechanism where you have one (Claude plan mode, Cursor plan); otherwise present the spec plainly and wait. Do not begin implementing without explicit approval.

On approval, start implementing. If you're Claude Code, the approval itself is recorded by gjalla automatically; nothing else needs to be marked.
