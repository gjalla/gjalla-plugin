---
name: conduct-post-mortem
description: >
  Conduct a blameless post-mortem analysis after an incident, outage, or significant bug.
  Use this skill when something went wrong in production and the team needs to understand
  what happened, why, and how to prevent it from happening again. Triggers on phrases like
  "post-mortem", "root cause analysis", "RCA", "what went wrong", "why did this break",
  or after resolving a production issue when the user wants to document learnings.
---

# Conduct Post-Mortem

Every major tech company — Google, Amazon, Meta, Netflix — conducts post-mortems after
significant incidents. The practice is borrowed from aviation and medicine: when things go
wrong, the goal is to learn from the failure, not to assign blame.

A good post-mortem produces two things: a shared understanding of what happened, and
concrete action items that make the system more resilient. A bad post-mortem produces a
document that nobody reads and action items that nobody does.

---

## When to Write a Post-Mortem

Write one when:
- A production outage affected users
- A significant bug reached production (even if caught quickly)
- An incident required emergency response (someone got paged)
- A near-miss that could have been much worse
- Data was lost, corrupted, or exposed
- A deployment had to be rolled back

The bar should be low. Writing post-mortems for small incidents builds the habit and catches
systemic issues that only show up in aggregate.

---

## Step 0: Load System Context for the Incident

Before analyzing what went wrong, understand how the system was supposed to work. Incident
analysis is dramatically better when informed by actual architecture, not reconstructed
from memory during a stressful review.

**If gjalla is available**, query these tools first:

- `get_context` — load the project architecture, capabilities, rules, and tech stack to
  understand how the affected components relate to each other. This helps identify
  contributing factors beyond the immediate root cause.
- `get_file_context` (path: files involved in the incident) — understand each file's
  architectural role, which elements it belongs to, and what rules apply. This reveals
  the actual path the failure took, which is often different from what people assume.
- `get_impact` — if there are uncommitted changes related to the incident fix, check
  their blast radius before committing.

**If gjalla is not available**, review monitoring dashboards, deployment logs, and the
incident timeline from the chat channel or incident management tool.

---

## Blameless Culture

The most important principle: **post-mortems are blameless.** Focus on systems and processes,
not individuals. The question is never "who screwed up?" — it's "what about our systems
allowed this to happen?"

This matters because:
- People won't report incidents honestly if they fear blame
- Most incidents have multiple contributing factors, not a single point of failure
- Blaming individuals prevents you from fixing the systemic issues that enabled the failure
- The person who "caused" the incident is usually the person who best understands the problem

In practice: use passive voice for human actions ("the config was deployed" not "Alice deployed
the config"), focus on process gaps rather than judgment calls, and ask "how could the system
have prevented this?" rather than "why didn't someone catch this?"

---

## Post-Mortem Template

```
# Post-Mortem: [Incident Title]

**Date**: [Date of incident]
**Duration**: [How long the incident lasted]
**Severity**: [SEV-1/2/3/4 or equivalent]
**Author**: [Who wrote this document]
**Reviewers**: [Who reviewed it]

## Summary
[2-3 sentence description of what happened, who was affected, and the business impact.
Write this so someone can understand the incident without reading the rest of the document.]

## Impact
- **Users affected**: [number or percentage]
- **Duration of impact**: [how long users experienced the issue]
- **Revenue impact**: [if applicable]
- **Data impact**: [any data loss or corruption]
- **SLO impact**: [how much error budget was consumed]

## Timeline

All times in UTC.

| Time | Event |
|------|-------|
| 14:00 | Deployment of v2.3.1 begins |
| 14:05 | Error rate increases from 0.1% to 5% |
| 14:08 | Pager fires: "API error rate > 1%" |
| 14:10 | On-call engineer acknowledges alert |
| 14:15 | Root cause identified: database migration timeout |
| 14:20 | Rollback initiated |
| 14:25 | Error rate returns to baseline |
| 14:30 | Incident resolved, monitoring confirmed stable |

## Root Cause

[Detailed technical explanation of what went wrong. Be specific — "the database query
timed out" is not enough. Explain *why* the query timed out, what made this deployment
different, and what the chain of events was from trigger to user impact.]

## Contributing Factors

[Most incidents have multiple contributing factors beyond the root cause. List them:]

1. [Factor 1 — e.g., "No integration test for the migration path with >1M rows"]
2. [Factor 2 — e.g., "Alerting threshold was too high to catch the initial degradation"]
3. [Factor 3 — e.g., "Runbook for database rollback was outdated"]

## What Went Well

[Acknowledge what worked. This reinforces good practices and provides balance:]

1. [e.g., "Alert fired within 3 minutes of the issue starting"]
2. [e.g., "Rollback procedure worked as documented"]
3. [e.g., "Cross-team communication was fast and effective"]

## What Went Wrong

[What failed or was missing in our processes and systems:]

1. [e.g., "Migration was not tested against production-scale data"]
2. [e.g., "No canary deployment was used for this release"]
3. [e.g., "The deployment proceeded during peak traffic hours"]

## Action Items

[Concrete, assignable, time-bound actions. Every action item should make a *specific*
future incident less likely or less severe.]

| Action | Owner | Priority | Due Date |
|--------|-------|----------|----------|
| Add integration test for migrations with >100K rows | [team/person] | P1 | [date] |
| Lower error rate alert threshold from 5% to 1% | [team/person] | P1 | [date] |
| Update database rollback runbook | [team/person] | P2 | [date] |
| Implement canary deployments for this service | [team/person] | P2 | [date] |
| Add deployment freeze during peak hours (12-2pm) | [team/person] | P3 | [date] |

## Lessons Learned

[Broader takeaways that apply beyond this specific incident. These often reveal systemic
issues worth addressing.]
```

---

## Conducting the Analysis

### The "5 Whys" Technique

Keep asking "why" until you reach a systemic cause:

1. Why did the service go down? → The database query timed out.
2. Why did the query time out? → The migration locked the table for 10 minutes.
3. Why did the migration take so long? → It was processing 5 million rows in a single transaction.
4. Why wasn't it batched? → The migration framework defaults to single-transaction.
5. Why wasn't this caught in testing? → Staging only has 1,000 rows.

The root cause isn't "the query timed out" — it's "we lack production-scale test data for
migration testing." The action item isn't "fix this query" — it's "set up production-scale
migration testing."

### Avoid These Traps

- **Stopping too early**: "Human error" is never a root cause. Ask why the system allowed
  the error to have that impact.
- **Boiling the ocean**: Not every action item needs to be a major project. Quick wins
  (better alerts, updated runbooks) are valuable and should be prioritized.
- **Action items without owners**: Unowned action items don't get done. Every item needs
  a specific owner and a due date.
- **Ignoring what went well**: If the alert fired quickly, say so. If the rollback was
  smooth, say so. Reinforcing good practices matters.

---

## Output

Save the post-mortem document at:
- `docs/post-mortems/YYYY-MM-DD-incident-title.md`, or
- wherever the team's convention places incident reports

After writing the post-mortem, summarize the key action items for the user and suggest
which ones to prioritize based on impact and effort.

### Attestation: Post-Mortem as Incident Attestation

The post-mortem attests to what happened, why, and what the team will do differently. When
gjalla context is available, the post-mortem can reference the actual system state to make
the analysis more precise.

```
## Post-Mortem Attestation

**System context at time of incident**: [from get_context — architecture, capabilities, rules]
**Files analyzed**: [from get_file_context — which files were traced during analysis]
**Impact assessment**: [from get_impact — blast radius of the fix]
**Capability gaps identified**: [from get_context — documented vs actual behavior]
**Rules/invariants violated**: [from get_context — which principles were breached]
**Action items created**: [count, with owners and due dates]
**Cross-system references**: [Slack threads, Notion docs, monitoring links for the incident]
```
