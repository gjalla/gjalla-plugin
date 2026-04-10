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

## How memories are persisted

Your memories are collected automatically by gjalla when you commit.
The post-commit hook runs `gjalla sync`, which gathers memories from
your agent's native memory system and uploads them to the gjalla
platform. From there, they're distributed to other agents and
sessions working on the same project.

**You don't need to call a special API to write memories.** Just use
your agent's native memory system (e.g., Claude Code's auto memory,
Cursor's context) as you normally would. gjalla handles the rest on
commit.

**What makes a good memory:**
- Patterns that worked ("this approach worked for X because Y")
- Failed attempts ("tried X, it broke because Y")
- Surprising discoveries about the codebase
- Decisions and their rationale
- Gotchas that aren't obvious from the code

Keep each memory focused — one insight per entry. Future sessions
read them in a list.

**If you don't commit:** memories from the current session won't be
persisted to gjalla until a commit happens. If you learn something
important but aren't ready to commit, note it in your agent's native
memory — it'll be collected on the next commit.

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
