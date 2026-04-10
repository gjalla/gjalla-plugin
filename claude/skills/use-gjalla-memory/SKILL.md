---
name: use-gjalla-memory
description: >
  Read and write project memories via gjalla. Use when you learn something
  non-obvious that future sessions should know, when debugging and finding
  a pattern worth recording, or when starting work and wanting to check
  what prior sessions discovered.
version: 0.1.0
metadata:
  openclaw:
    emoji: "🧠"
    homepage: https://gjalla.io
    tags:
      - memory
      - knowledge
      - persistence
      - collaboration
---

# Use gjalla Memory

Memories are persistent knowledge that survives session boundaries.
They capture what you learn — patterns, gotchas, decisions, failure
lessons — so future sessions (yours or a teammate's) don't have to
rediscover them.

---

## When to read memories

- **Before editing a file or area** — call `get_file_context` or
  `get_project_memories` to check if prior sessions recorded anything
  about this code.
- **When debugging** — someone may have hit this bug before and
  documented the root cause or workaround.
- **When planning** — architectural decisions and constraints are
  often captured as memories, complementing the formal rules.

---

## When to write memories

- **After a successful pattern** — "this approach worked well for X
  because Y" helps future sessions make the same call faster.
- **After a failed attempt** — "tried X, it broke because Y, Z is
  the right approach" prevents re-treading dead ends.
- **After a surprising discovery** — something non-obvious about the
  codebase, a quirk, a dependency relationship that isn't in the
  architecture model yet.
- **After a decision** — why you chose approach A over B, especially
  if the tradeoff isn't self-evident from the code.

---

## How to write

Write memories via the gjalla memory API. Each memory should have:

- **Content** — markdown, concise. Lead with the actionable insight.
- **Category** — what kind of knowledge: `pattern`, `gotcha`,
  `decision`, `failure`, `architecture`, `process`.
- **Element ID** (optional) — tie the memory to a specific
  architecture element if it's scoped (e.g., `architecture.api-server`).

Keep memories focused. One insight per memory. Future sessions will
read them in a list — a wall of text defeats the purpose.

---

## How to read

- `get_project_memories` — all memories for the project, optionally
  filtered by category or element.
- `get_file_context(file_path="...")` — returns memories relevant to
  a specific file alongside its architectural context.
- `get_element_details(element_id="...")` — returns memories tied to
  a specific architecture element.

---

## Memory vs rules vs specs

- **Memories** are informal, agent-authored, accumulated over time.
  They capture soft knowledge.
- **Rules** are formal constraints (principles, ADRs, checks) that
  code must comply with. Violating a rule should block a commit.
- **Specs** are behavioral contracts — what must be true when a
  feature ships. They're verifiable.

If what you learned is a hard constraint, propose it as a rule via
`add_rule` instead of writing a memory.
