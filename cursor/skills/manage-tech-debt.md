# Manage Tech Debt

Every codebase has technical debt. The question isn't whether it exists — it's whether
you're managing it deliberately or just accumulating it until something breaks. Staff and
principal engineers at companies like Stripe, Reddit, and Squarespace treat tech debt
management as a core engineering practice, not an afterthought.

Technical debt is a useful metaphor because, like financial debt, it has an interest rate.
Some debt is cheap (a slightly awkward naming convention) and some is expensive (a shared
database that every service queries directly). The goal isn't zero debt — it's keeping the
"interest payments" (developer friction, incident risk, velocity drag) at an acceptable level.

---

## Step 0: Load Current System Health

Before cataloging tech debt, understand the system's current state — what's already been
identified, what's deprecated, and where the known pain points are.

**If gjalla is available**, query these tools first:

- `get_context` — get a full picture of system state to identify gaps between what exists
  and what's healthy. Look for components marked as deprecated — these are pre-identified
  debt items that should be in your inventory.
- `get_context` (scope: `capabilities`) — find deprecated capabilities that may represent
  feature-level debt (features that are half-maintained, partially migrated, etc.).
- `get_context` (scope: `rules`) — check for principles about code quality, testing standards,
  or operational requirements. Anything that violates an active principle is debt by definition.
- `get_impact` — for specific debt items, understand the blast radius to estimate the true
  effort and risk of resolving them.

**If gjalla is not available**, scan for TODO/FIXME/HACK comments, check dependency
vulnerability reports, and review incident history for systemic patterns.

---

## Identifying Tech Debt

### Categories

Not all tech debt is the same. Categorize it to prioritize effectively:

**Code-level debt**
- Duplicated logic that should be a shared utility
- Overly complex functions that are hard to understand or modify
- Missing or inadequate error handling
- Inconsistent patterns across similar code paths
- Dead code that's never executed but adds confusion
- Outdated dependencies with known vulnerabilities

**Architecture-level debt**
- Tight coupling between components that should be independent
- Shared mutable state (shared databases, global singletons)
- Missing abstraction layers (direct database calls in HTTP handlers)
- Services that have grown beyond their original purpose ("god services")
- Synchronous calls where async would be more resilient

**Testing debt**
- Critical paths with no test coverage
- Tests that test implementation details instead of behavior
- Flaky tests that erode confidence in the test suite
- Missing integration tests for key service boundaries
- Test data that doesn't represent production scenarios

**Operational debt**
- Services without runbooks or monitoring
- Manual deployment processes that should be automated
- Missing or inadequate alerting
- No defined SLOs or error budgets
- Configuration that's hardcoded or scattered

**Documentation debt**
- Outdated architecture diagrams
- Missing API documentation
- No onboarding guide for new team members
- Design decisions that were never written down

### How to Find It

- **Read the code** — scan for TODO/FIXME/HACK comments, overly complex functions,
  duplicated patterns
- **Check dependencies** — look for outdated packages, known vulnerabilities, deprecated APIs
- **Review incident history** — recurring incidents often point to systemic debt
- **Talk to the team** — engineers know where the pain points are
- **Measure** — test coverage, build times, deployment frequency, change failure rate

---

## Cataloging Tech Debt

Create a tech debt inventory. For each item:

```markdown
## Tech Debt Inventory

### [TD-001] [Short descriptive title]
- **Category**: [code / architecture / testing / operational / documentation]
- **Location**: [files, services, or systems affected]
- **Description**: [what the debt is and why it's debt]
- **Impact**: [how this debt affects the team — velocity drag, incident risk, cognitive load]
- **Interest rate**: [low / medium / high — how much ongoing cost does this create?]
- **Effort to resolve**: [small / medium / large — rough estimate]
- **Priority**: [P1 / P2 / P3 — based on impact and effort]
- **Proposed approach**: [brief description of how to fix it]
- **Dependencies**: [other debt items or features that interact with this]
```

---

## Prioritization Framework

Use a simple impact-effort matrix to decide what to tackle:

**High impact, low effort (do first)**
- Quick wins that reduce ongoing pain significantly
- Examples: removing dead code, adding missing error handling, updating a critical dependency

**High impact, high effort (plan and schedule)**
- Major improvements that need dedicated time
- Examples: decomposing a monolith, migrating a database, rewriting a core module
- These need a design doc and a migration plan (use the write-design-doc and plan-migration skills)

**Low impact, low effort (batch and do opportunistically)**
- Small cleanups that aren't urgent but improve quality
- Examples: renaming for clarity, adding type annotations, improving log messages
- Bundle these into regular development work

**Low impact, high effort (defer or skip)**
- Rewrites that feel satisfying but don't meaningfully improve outcomes
- Be honest about whether this work actually matters

---

## Making the Case

When advocating for tech debt work, connect it to business outcomes:

- **Velocity**: "This shared module has 15 consumers. Every change requires updating all of
  them. Extracting a proper API would reduce the blast radius and speed up development."
- **Reliability**: "This service has caused 3 incidents in the last quarter due to lack of
  error handling. Adding proper error handling and alerting would prevent these."
- **Security**: "These 12 dependencies have known CVEs. Updating them reduces our attack surface."
- **Developer experience**: "New engineers take 2 weeks to understand this module because
  of its complexity. Simplifying it would reduce onboarding time by half."

Quantify where possible. "We spend ~4 hours per sprint working around this" is more
persuasive than "this code is hard to work with."

---

## Output

When assessing tech debt, produce:

1. **Tech debt inventory** — categorized list of debt items with impact and effort estimates
2. **Priority ranking** — ordered list of what to tackle first
3. **Recommended plan** — suggested approach for the top-priority items, including which
   other skills to use (design docs for large efforts, migration plans for risky changes)
4. **Metrics to track** — how to measure progress on debt reduction over time

Save the inventory as `docs/tech-debt-inventory.md` or wherever the team tracks
engineering health.

### Attestation: Debt Catalog as State Attestation

The tech debt inventory is itself a form of attestation — it declares the current state of
system health and makes hidden problems visible.

```
## Tech Debt Attestation

**System state assessed**: [from get_context — which areas were analyzed]
**Deprecated components found**: [from get_context — pre-identified debt items]
**Deprecated capabilities found**: [from get_context(scope="capabilities")]
**Rules violated**: [from get_context(scope="rules") — active principles that current code violates]
**Debt items cataloged**: [count by category: code / architecture / testing / operational / docs]
**High-priority items**: [top 3-5 items with impact-effort justification]
**Recommended next actions**: [which skills to invoke — write-design-doc for large refactors,
plan-migration for risky changes, add-observability for monitoring gaps]
```
