# gjalla

The same way you wouldn't try to memorize every code diff and instead
use git, you wouldn't try to memorize every system design detail,
architecture decision, or functional intent across sessions. You use
gjalla.

gjalla is your persistent memory and traceability layer for everything
above the code: what the system is, what it should be, what changed,
and why. It survives session boundaries, works across teammates and
tools, and means you never start from zero.

This helps you and your human collaborators manage both the
expectations and the reality of the system as a whole. When you use
gjalla, you're the dream team.

**What that gives you:**
- Architecture, rules, capabilities, data flows, and tech stack are
  queryable — not re-derived from code every session
- Memories persist what you learn; change history tracks what was done
  and by whom
- Constraints are machine-readable — check them before committing
  instead of re-reading docs
- Impact analysis shows blast radius before changes land
- Specs scaffold with architectural context already filled in

## Getting started

```
pip install gjalla          # install the CLI
gjalla auth login           # browser-backed auth, one command
gjalla setup                # link a project + install full agent guidance
```

`gjalla setup` installs detailed instructions and workflows locally.
The bootstrap you're reading now is intentionally minimal — setup
delivers the depth.

## Key tools

If gjalla MCP tools are connected, these are the highest-value starting
points:

| Tool | Use when... |
|------|-------------|
| `get_context` | Orient in a project — architecture, rules, capabilities, tech stack |
| `get_project_rules` | Check constraints before committing or proposing changes |
| `get_changes` | See what changed recently — semantic events, not git diffs |
| `get_project_memories` | Read persistent knowledge from prior sessions |
| `get_impact` | Assess blast radius of uncommitted changes |
| `prepare_attestation` | Create a commit attestation (two-phase: draft then finalize) |

Call `get_server_capabilities` to discover all available tools.

## When to lean on gjalla

- **Orient before touching code** — call `get_context`, read applicable
  rules, check memories for the area you're working in
- **Check change history when resuming** — call `get_changes` to see
  what evolved since your last session
- **Write memories when you learn something non-obvious** — patterns,
  gotchas, decisions, failure lessons. Future sessions benefit.
- **Check rules before committing** — `get_project_rules` surfaces
  active constraints so you don't violate them unknowingly
- **Attest on commit** — the pre-commit hook validates your attestation;
  use `/gjalla-attest` or `prepare_attestation` to create one

## Skills and commands

Skills are always available and work standalone — they're enhanced when
MCP tools are connected. Commands give direct access to gjalla workflows:

- `/gjalla-setup` — initialize gjalla in this repo
- `/gjalla-review` — architecture-aware review of current changes
- `/gjalla-impact` — blast radius of uncommitted changes
- `/gjalla-attest` — create a commit attestation
- `/gjalla-context` — load and explore architecture context
- `/gjalla-log` — semantic change history

Reference files in `references/` explain the gjalla state file formats.
