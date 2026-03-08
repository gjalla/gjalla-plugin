---
name: analyze-before-coding
description: >
  Stop and analyze before writing any code. Review the problem space — trace what the change
  touches, estimate the blast radius, and mentally simulate the system with the change in
  place. Use this skill whene you're about to implement something that modifies existing
  behavior, touches shared components, or interacts with more than one part of the system.
  Triggers on implementation tasks (features, bugs, refactors). Even if the user says "just
  do it", take 60 seconds to load the context first.
---

# Analyze Before Coding

When a senior engineer reads a ticket, they don't start typing. They sit and think. That
thinking looks like doing nothing, but it's actually three distinct cognitive processes
running simultaneously: impact loading, blast radius estimation, and mental simulation.
This skill makes those invisible processes explicit.

The goal isn't to produce a document (that's what write-design-doc is for). The goal is
to build a mental model of the change before touching code, so that when you do start
coding, you're making informed decisions rather than discovering problems halfway through.

---

## Step 0: Load System Context

Before analyzing anything manually, check whether the system's architecture, rules, and
dependency graph are available. This turns the analysis from educated guesswork into
ground-truth reasoning.

**If gjalla is available**, query these tools first:

- `get_context(scope="architecture")` — load the system's containers, relationships, and
  design principles. This gives you the map of what exists before you trace dependencies.
- `get_context(scope="rules")` — load active ADRs, principles, and invariants. These are
  the constraints your change must respect. If an ADR says "all new services must be
  stateless," that shapes your entire approach.
- `get_file_context(file_path="...")` — before touching a specific file, get its
  architectural role and relationships so you understand what you're modifying.
- `get_impact()` — get the real blast radius from the actual dependency graph (uses git
  diff HEAD). This replaces manual import tracing with the truth.

**If gjalla is not available**, proceed with manual analysis (Steps 1-3 below). The
thinking process is the same — gjalla just gives you higher-fidelity inputs.

---

## Step 1: Impact Loading

Before changing anything, trace what the change touches. This isn't just "which files will
I edit" — it's the full web of dependencies, consumers, and side effects.

### Trace the Dependency Web

Starting from the component you're about to change, map outward:

- **What does this component depend on?** Database tables, external APIs, shared libraries,
  configuration values, environment variables, other services.
- **What depends on this component?** Other services that call it, UI components that render
  its output, background jobs that consume its events, tests that assert on its behavior.
- **What shares state with this component?** Database tables written by multiple services,
  shared caches, message queues, global configuration.

You don't need to draw a formal diagram. The point is to hold the dependency web in your
head so you can reason about second-order effects.

### Identify the Contracts

For each dependency boundary, identify the implicit or explicit contracts:

- API contracts (request/response shapes, status codes, error formats)
- Data contracts (schema expectations, invariants, foreign key relationships)
- Behavioral contracts (ordering guarantees, timing assumptions, idempotency expectations)
- Performance contracts (expected latency, throughput, resource usage)

Your change must preserve these contracts, or you need to explicitly plan for how consumers
will adapt.

### Ask: "What Doesn't Know About This Change?"

The most dangerous impacts are the ones where a system depends on behavior you're about to
change, but nobody told that system. Look for:

- Hardcoded assumptions about the current behavior
- Cached values that will become stale
- Background jobs running on an older understanding of the data
- Monitoring or alerting that assumes current patterns
- Documentation or runbooks that describe the current behavior

---

## Step 2: Blast Radius Estimation

Now that you know what the change touches, estimate how bad it would be if you got it wrong.

### Categorize the Risk

Ask yourself:

- **If this change has a bug, who is affected?**
  - One user? A subset of users? All users? Internal services? External partners?
- **If this change breaks, how quickly will we know?**
  - Immediately (500 errors)? After a delay (data corruption)? Weeks later (subtle logic bug)?
- **If this change breaks, how quickly can we recover?**
  - Instant rollback? Feature flag toggle? Database migration reversal? Manual data repair?
- **What's the worst-case scenario?**
  - Downtime? Data loss? Security breach? Financial impact? Regulatory violation?

### Calibrate Your Approach

The blast radius determines how careful to be:

**Small blast radius** (feature-specific, easily reversible):
- Implement directly, test well, deploy normally
- A feature flag is nice but not essential

**Medium blast radius** (affects multiple features or teams):
- Write a brief design sketch before implementing
- Use a feature flag for rollout
- Add specific monitoring for the change
- Plan a rollback path

**Large blast radius** (affects core systems, hard to reverse):
- Write a full design doc (use the write-design-doc skill)
- Get review from someone who knows the affected systems
- Use progressive delivery (canary → staged rollout)
- Write a migration plan (use the plan-migration skill)
- Add alerts specifically for this change

---

## Step 3: Mental Simulation

Walk through the system with your change in place. This is the most valuable and most
invisible part of senior engineering — running integration tests in your head.

### Simulate the Happy Path

Pick the most common use case and trace a request through the entire system:

1. A request arrives at the entry point
2. It gets routed to your modified code
3. Your code executes the new logic
4. It interacts with dependencies (database, cache, external services)
5. The response flows back to the caller
6. Any side effects (events, notifications, audit logs) fire

At each step, check: "Does this still work? Does anything see unexpected data? Does timing
change? Does the response shape change?"

### Simulate the Failure Paths

Now run the same simulation, but break things:

- What happens if the database query times out?
- What happens if the external API returns an error?
- What happens if the input is malformed?
- What happens if this code runs concurrently with itself?
- What happens if this code runs during a deployment (old and new versions coexisting)?
- What happens if the feature flag is half-rolled-out?

Each of these simulations might reveal a problem you need to handle in your implementation.

### Simulate the Edge Cases

Think about the boundaries:

- Empty inputs, null values, maximum-length strings
- First-time users vs. power users with years of data
- Midnight, month boundaries, daylight saving time transitions
- Free-tier vs. paid-tier behavior differences
- Single-item vs. batch operations

---

## Output

This skill doesn't produce a formal document. Instead, it produces a brief summary of what
you found — something like:

```
## Pre-Implementation Analysis

**Change**: [what you're about to do]

**Touches**: [components, services, tables affected]
**Depended on by**: [what will break if this is wrong]
**Blast radius**: [small/medium/large] — [1-sentence justification]

**Key risks identified**:
- [risk 1 and how you'll handle it]
- [risk 2 and how you'll handle it]

**Approach**: [how the blast radius calibrates your implementation approach]
```

Write this as a comment at the top of your PR, or share it with the user before starting
implementation. It takes 5 minutes and prevents hours of rework.

**Present this to the human for review before proceeding.** This is the intent declaration —
the human should see the blast radius and key risks *before* any code is written. If the
analysis changes their mind about the approach, better to know now.

### After Implementation: Attestation

Once the work is done, revisit your pre-implementation analysis and attest to what actually
happened:

```
## Implementation Attestation

**Planned change**: [what you said you'd do]
**Actual change**: [what you actually did]
**Predicted blast radius**: [what you estimated]
**Actual blast radius**: [what was actually affected]
**Rules checked**: [ADRs/principles from get_context(scope="rules") that applied]
**Rules followed**: [which ones you respected]
**Rules deviated from**: [any deviations, with justification]
**Surprises**: [anything you discovered during implementation that wasn't in the analysis]
```

If the attestation differs significantly from the intent declaration, explain why. This
audit trail helps the team understand not just what changed, but whether the agent's
analysis was accurate — which builds (or erodes) trust over time.

---

## When to Skip This

You can skip the full analysis for:
- Typo fixes, comment updates, documentation changes
- Adding a log line or metric
- Changes isolated to test files
- Changes you've already analyzed as part of a design doc

Even for these, a 10-second mental check is worthwhile: "Is there any way this seemingly
trivial change could break something?" Sometimes the answer is yes.
