---
name: write-runbook
description: >
  Write operational runbooks for services and systems — the documented procedures that on-call
  engineers follow when something goes wrong. Use this skill when building or modifying a
  production service, after an incident reveals a gap in operational documentation, or when
  the user asks for docs. Triggers on phrases like "runbook", "how to debug this", or when
  deploying a new service that doesn't have operational documentation. If you build
  something that will run in production and there's no runbook, this skill should trigger.
---

# Write Runbook

Google's SRE book made runbooks famous, but every company that runs reliable services uses
them. A runbook is the difference between "the on-call engineer diagnosed and fixed this in
10 minutes" and "we escalated to the original author who was on vacation."

The purpose of a runbook is to enable *anyone* on the on-call rotation to handle the most
common problems with a service, even if they didn't build it. It transfers operational
knowledge from the builder's head into a durable, findable document.

---

## Step 0: Load Service Architecture and Operational Context

A runbook is only as good as its understanding of the service. Before writing one, load
the actual architecture rather than guessing.

**If gjalla is available**, query these tools first:

- `get_context` (path: `<service-slug>`) — get the deep dive on this specific component:
  its connections, decisions, and knowledge graph context. This is the primary source for
  the "Service Overview" and "Architecture" sections.
- `get_context` (scope: `architecture`) — understand where this service fits in the broader
  system. Identify upstream consumers and downstream dependencies for the runbook.
- `get_context` (scope: `data_flows`) — trace how data moves through this service. Data flow
  diagrams make excellent additions to the runbook's Architecture section.
- `get_context` (scope: `rules`) — check for operational ADRs (e.g., "all services must have
  runbooks covering X, Y, Z scenarios").

**If gjalla is not available**, review the service's README, existing documentation,
monitoring dashboards, and recent incident history.

---

## Runbook Structure

Every service should have a runbook. Organize it like this:

```
# [Service Name] Runbook

## Service Overview
What this service does, who depends on it, and why it matters. Write this for someone
who has never seen the service before and just got paged at 3am.

- **What it does**: [1-2 sentence description]
- **Who depends on it**: [list of upstream consumers]
- **What it depends on**: [list of downstream dependencies]
- **Team/owner**: [team name and contact channel]
- **Repository**: [link]
- **Dashboard**: [link to monitoring dashboard]
- **Logs**: [how to find logs — query, index, link]

## Architecture
Brief description of the service's components and how they interact. Include a simple
diagram if the service has more than 2-3 components. Note which components are stateful
vs stateless — this affects debugging and recovery strategies.

## Common Alerts

### [Alert Name]
- **What it means**: [plain-language description of what triggered the alert]
- **Severity**: [page / ticket / informational]
- **Likely causes**: [ordered by frequency]
  1. [Most common cause]
  2. [Second most common cause]
  3. [Less common cause]
- **Diagnosis steps**:
  1. [First thing to check — include actual commands/queries]
  2. [Second thing to check]
  3. [How to confirm root cause]
- **Mitigation**:
  1. [Immediate action to stop the bleeding]
  2. [Longer-term fix]
- **Escalation**: [who to contact if the above doesn't work]

### [Next Alert]
...

## Common Operations

### Restarting the service
[Exact commands, expected behavior, things to watch for]

### Scaling up/down
[How to add or remove capacity, any constraints]

### Deploying a new version
[Deployment process, verification steps, rollback procedure]

### Database operations
[Common queries, safe vs dangerous operations, how to take backups]

## Troubleshooting Guide

### Service is slow
1. Check [dashboard link] for latency trends
2. Check dependency health: [commands/queries]
3. Check resource utilization: [commands/queries]
4. Common causes: [list with fixes]

### Service is returning errors
1. Check error logs: [query/command]
2. Identify error pattern: [what to look for]
3. Common causes: [list with fixes]

### Service is down
1. Check if the process is running: [command]
2. Check recent deployments: [how to check]
3. Check infrastructure: [what to verify]
4. Recovery procedure: [step by step]

## Contacts and Escalation
- **Primary on-call**: [rotation link]
- **Secondary on-call / team lead**: [contact info]
- **Dependent team contacts**: [for cross-service issues]
- **Incident command**: [how to declare a formal incident]
```

---

## Writing Principles

**Write for 3am.** The reader is tired, stressed, and possibly unfamiliar with the service.
Use short sentences, clear steps, and actual commands they can copy-paste. Don't make them
think more than necessary.

**Include the actual commands.** Don't say "check the logs" — say exactly how to check the
logs, with the query or command to run. Don't say "restart the service" — give the exact
command and what the expected output looks like.

**Order by frequency.** List the most common causes first. If 80% of alerts are caused by
one thing, put that thing at the top of the diagnosis section.

**Keep it current.** A runbook that describes last year's architecture is worse than no
runbook — it gives false confidence. After every incident that reveals a gap, update the
runbook. After every architecture change, review the runbook.

**Test it.** Have someone who didn't write the runbook try to follow it. If they get stuck,
the runbook needs improvement. Monthly "game days" where the team practices using runbooks
are ideal.

---

## Output

Save runbooks in a consistent location:
- `docs/runbooks/[service-name].md`, or
- `runbook.md` in the service's repository root, or
- wherever the team's convention places operational docs

After writing the runbook, note any alerts or monitoring that should exist but doesn't,
and flag those for the user to set up.

### Attestation: Runbook as Operational Attestation

The runbook attests to the operational readiness of a service — it documents that the team
has thought through failure modes and has procedures for handling them.

```
## Runbook Attestation

**Service architecture loaded**: [from get_context(path=<service-slug>) — component details]
**Dependencies documented**: [from get_context(scope="architecture") — upstream/downstream services]
**Data flows traced**: [from get_context(scope="data_flows") — critical data paths covered]
**Alert coverage**: [list of alerts documented with runbook procedures]
**Gaps identified**: [alerts or scenarios that need runbook coverage but don't have it yet]
**Rules respected**: [from get_context(scope="rules") — operational ADRs followed]
```
