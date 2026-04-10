---
name: orient-in-project
description: >
  Cold-start orientation in a gjalla-enabled repo. Use when you're starting
  a new session, picking up unfamiliar code, or resuming after time away.
  Loads architecture context, active rules, recent changes, and relevant
  memories so you understand the system before touching it.
version: 0.1.0
metadata:
  openclaw:
    emoji: "🧭"
    homepage: https://gjalla.io
    tags:
      - orientation
      - context
      - onboarding
      - architecture
---

# Orient in Project

Understand the system before touching it. This skill loads everything you
need to work confidently — architecture, rules, recent changes, and
memories — so you don't re-derive context from code or make changes that
conflict with established patterns.

---

## Step 1: Load architecture context

Call `get_context` to get the full picture: elements, connections, rules,
capabilities, tech stack, and data flows.

If `get_context` returns empty data, the project may need initial
analysis. Suggest `gjalla setup` or `gjalla state bootstrap`.

---

## Step 2: Check active rules

Call `get_project_rules` to load principles, ADRs, and constraints.
These are the guardrails for any work you do. Read them before
proposing changes — a rule violation caught at commit time costs more
than one caught at planning time.

---

## Step 3: Check what changed recently

Call `get_changes(since="7d")` to see the semantic change history.
This tells you what evolved since your last session (or since the
project was last touched). Look for:

- New rules or modified constraints
- Architecture elements that were added or restructured
- Capabilities that changed status

If you're resuming specific prior work, narrow the filter:
`get_changes(element="architecture.api-server")` or
`get_changes(primitive_type="rule")`.

---

## Step 4: Read relevant memories

Call `get_project_memories` to see what prior sessions learned.
Memories capture patterns, gotchas, decisions, and failure lessons
that aren't in the code. They're the institutional knowledge layer.

If you're working on specific files, `get_file_context(file_path="...")`
returns both architectural role and relevant memories for that area.

---

## Step 5: Summarize your orientation

Before starting work, surface a brief summary:

- What this project is (from architecture context)
- What constraints apply (from rules)
- What changed recently (from change history)
- What prior sessions learned about this area (from memories)

This summary grounds your work and gives your human collaborator
confidence that you understand the system before modifying it.
