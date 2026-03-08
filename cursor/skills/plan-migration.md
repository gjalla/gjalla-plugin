# Plan Migration

Staff and principal engineers at Amazon, Stripe, and Google don't just write code — they
plan how that code gets to production safely. Every deployment is a potential incident, and
the difference between a smooth rollout and a 3am page is usually the quality of the
migration plan.

This skill ensures that every significant change has a deployment strategy, a rollback plan,
and clear success criteria before anyone hits merge.

---

## Step 0: Load System State and Impact Analysis

Migrations are inherently risky because they change shared state. Before planning one,
understand what you're changing and what depends on it.

**If gjalla is available**, query these tools first:

- `get_context` — get a comprehensive snapshot of the current system state. This is
  your "before" picture. After migration, the attestation compares the new state against this.
- `get_impact` — analyze the full blast radius using the current git diff. A migration plan
  is only as good as its understanding of what could break.
- `get_context` (scope: `data_flows`) — trace how data moves through the components being
  migrated. Data flows that cross migration boundaries are the highest-risk points.
- `get_context` (scope: `rules`) — check for migration-related ADRs (e.g., "all migrations
  must be reversible", "database changes require expand-contract pattern").
- `get_context` (path: `<element-slug>`) — deep dive into the specific component to
  understand its connections and dependencies.

**If gjalla is not available**, analyze the codebase for dependencies, check database
relationships, and review recent incident history related to the system being migrated.

---

## When You Need a Migration Plan

Any change that involves:
- Database schema changes (adding, modifying, or removing columns/tables/indexes)
- Data transformations on existing records
- API contract changes that affect consumers
- Infrastructure changes (new services, config changes, resource scaling)
- Feature launches with uncertain performance or user impact
- Changes to shared libraries or platforms used by other teams

---

## The Expand-Contract Pattern

Most safe migrations follow the expand-contract (also called parallel change) pattern:

1. **Expand** — add the new thing alongside the old thing (both work simultaneously)
2. **Migrate** — move consumers/data from old to new
3. **Contract** — remove the old thing once migration is complete

This pattern applies to database schemas, APIs, configuration formats, and service
architectures. The key insight is that you never have a moment where things are broken —
old and new coexist during the transition.

### Database Schema Example

Bad (breaks existing code):
```
ALTER TABLE users RENAME COLUMN name TO full_name;
```

Good (expand-contract):
```
-- Step 1: Expand — add new column
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);

-- Step 2: Migrate — backfill data, update code to write both columns
UPDATE users SET full_name = name WHERE full_name IS NULL;

-- Step 3: Contract — after all code reads from full_name
ALTER TABLE users DROP COLUMN name;
```

Each step is a separate deployment with its own verification.

---

## Migration Plan Template

For every significant migration, document:

```
# Migration Plan: [Title]

## Overview
What's changing, why, and what systems are affected.

## Pre-Migration Checklist
- [ ] Rollback plan documented and tested
- [ ] Monitoring dashboards updated to track migration progress
- [ ] Alerts configured for migration-specific failure modes
- [ ] Feature flags in place for new behavior
- [ ] Stakeholders notified of timeline and potential impact
- [ ] Runbook updated with migration-specific procedures

## Migration Steps

### Step 1: [Description]
- **What**: What changes are deployed
- **How to verify**: How to confirm this step succeeded
- **Rollback**: How to undo this specific step
- **Duration**: Expected time for this step
- **Risk**: What could go wrong

### Step 2: [Description]
...

## Rollback Plan
For each step, describe how to reverse it. The rollback should be:
- Faster than the forward migration
- Tested before the migration starts
- Executable by the on-call engineer (not just the author)
- Automated where possible

## Success Criteria
How do you know the migration is complete and successful?
- Metric thresholds (error rates, latency, throughput)
- Data validation queries
- Functional verification steps

## Timeline
- Migration start: [date/time]
- Expected completion: [date/time]
- Point of no return (if any): [step and reasoning]
```

---

## Feature Flags

Use feature flags to decouple deployment from release. This gives you an instant rollback
mechanism that doesn't require a code deployment.

### When to Use Feature Flags

- New user-facing features with uncertain reception or performance
- Changes to critical paths (checkout, authentication, data pipeline)
- Gradual rollouts (1% → 10% → 50% → 100%)
- A/B testing new behavior

### Feature Flag Hygiene

Feature flags are technical debt by nature. For each flag:
- Document its purpose and expected lifetime
- Set a cleanup date (typically 2-4 weeks after 100% rollout)
- Ensure code works correctly with the flag both on AND off
- Remove the flag and dead code path once the rollout is complete

---

## Progressive Delivery

For high-risk changes, roll out gradually:

1. **Canary** — deploy to a small percentage of traffic (1-5%) and monitor
2. **Staged rollout** — increase to 10%, 25%, 50%, 100% with monitoring at each stage
3. **Auto-rollback** — wire rollout progression to SLO signals; if error rate or latency
   degrades, automatically halt or roll back

### Monitoring During Rollout

During any progressive rollout, watch:
- Error rates (compare canary vs baseline)
- Latency percentiles (p50, p95, p99)
- Business metrics (conversion rate, throughput)
- Resource utilization (CPU, memory, connection pools)

Define thresholds in advance: "If p99 latency increases by more than 20% or error rate
exceeds 0.5%, halt the rollout."

---

## Output

When planning a migration, produce:

1. **Migration plan document** — following the template above
2. **Feature flag configuration** — if applicable
3. **Rollback scripts or procedures** — tested and documented
4. **Monitoring additions** — dashboards and alerts specific to the migration

Save the migration plan alongside the code, typically in `docs/migrations/` or as a
comment in the PR/MR description.

### Attestation: Migration Plan as Intent Declaration

The migration plan IS the intent declaration. It tells the human exactly what will change,
what could break, and how to roll back. After execution, the attestation confirms what
actually happened.

```
## Migration Attestation

**System state before**: [from get_context — snapshot of pre-migration state]
**Blast radius predicted**: [from get_impact — components expected to be affected]
**Blast radius actual**: [what was actually affected during migration]
**Data flows verified**: [from get_context(scope="data_flows") — data paths that were tested]
**Rules followed**: [from get_context(scope="rules") — migration-related ADRs respected]
**Steps completed**: [list of migration steps with pass/fail status]
**Rollback tested**: [yes/no — was the rollback plan verified?]
**Success criteria met**: [metrics/validation results confirming successful migration]
```
