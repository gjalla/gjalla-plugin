# gjalla plugin

Persistent memory and traceability for agentic engineering. The same way you wouldn't memorize every code diff and instead use git, you wouldn't try to memorize every system design detail, architecture decision, or functional intent across sessions. You use gjalla.

This plugin connects your coding agent to the gjalla platform for architecture truth, rule enforcement, semantic change history, and persistent memory — across sessions, teammates, and tools.

## Getting started

```bash
pip install gjalla
gjalla auth login       # browser-backed auth, one command
gjalla setup            # link a project + install full agent guidance
```

`gjalla setup` installs detailed agent instructions locally. The plugin provides bootstrap orientation; setup delivers the depth.

## What's included

- **Bootstrap agent instructions** — orients the agent on what gjalla is, how to start, and which tools matter most
- **8 skills** — engineering workflows for planning, reviewing, orientation, memory, change history, and more
- **6 commands** — `/gjalla-context`, `/gjalla-review`, `/gjalla-impact`, `/gjalla-attest`, `/gjalla-setup`, `/gjalla-log`
- **MCP server** — connects to [gjalla](https://gjalla.io) for live architecture context, change history, impact analysis, and rule enforcement
- **Reference docs** — annotated examples for gjallastate, gjallamap, gjallarules, and attestation file formats

## Skills

| Skill | What it does |
|-------|-------------|
| `spec-create` | Define what should be true before writing code |
| `spec-review` | Review a spec from multiple expert perspectives |
| `task-breakdown` | Break a feature into sized, dependency-ordered task waves |
| `verify` | Verify implementation against spec acceptance criteria |
| `conduct-post-mortem` | Blameless incident analysis with architecture context |
| `orient-in-project` | Cold-start orientation — architecture, rules, changes, memories |
| `use-gjalla-memory` | Read and write persistent project knowledge |
| `read-change-history` | Query semantic change events via `get_changes` |

## Key MCP tools

| Tool | Use when... |
|------|-------------|
| `get_context` | Orient in a project |
| `get_project_rules` | Check constraints before committing |
| `get_changes` | See what changed recently — semantic events, not git diffs |
| `get_project_memories` | Read persistent knowledge from prior sessions |
| `get_impact` | Assess blast radius of uncommitted changes |
| `prepare_attestation` | Create a commit attestation |

Call `get_server_capabilities` to discover all available tools.

## Installation

### Claude Code

```
claude plugin add gjalla
```

### Cursor

Install from the Cursor Marketplace, or add the repo manually.

### OpenClaw

```
openclaw plugin add gjalla
```

## License

MIT
