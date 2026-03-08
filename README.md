# gjalla plugin

Architecture visibility and control for agentic engineering. Because coding agents work faster than we do, and they do it without the context and processes we do, collaborating with them can be tedious and frustrating. This repo includes 15 skills that encode senior-engineer thinking patterns, plus an MCP server that a) gives your agent system-level context, b) points you toward what AI-generated changes are important for you to review, and c) lets you define and enforce rules for your process and business logic.

## What's included

- **15 engineering skills** — thinking patterns for planning changes, reviewing code, managing debt, writing tests, and more. These work standalone with any AI agent.
- **MCP server** — connects to [gjalla](https://gjalla.io) for live architecture context, system-level impact analysis, and rule enforcement. Makes your agent outputs dramatically better.
- **Reference docs** — gjallastate/gjallamap/gjallarules/attestation file format specs with annotated examples.

## Skills

| Skill | What it does |
|-------|-------------|
| `analyze-before-coding` | Understand architecture before writing code |
| `clarify-requirements` | Surface ambiguity and missing specs before implementation |
| `match-codebase-conventions` | Match existing patterns, naming, and style |
| `design-for-change` | Design abstractions that accommodate future changes |
| `architect-error-handling` | Design error handling aligned with system architecture |
| `triage-scope` | Identify and separate adjacent issues from current task |
| `write-design-doc` | Write design documents for large features |
| `design-api` | Design APIs consistent with existing surface area |
| `prepare-for-review` | Pre-PR cleanup and completeness check |
| `perform-review` | Code review against architecture and rules |
| `add-observability` | Design logging, metrics, and tracing that match the architecture |
| `plan-migration` | Plan safe migrations with rollback strategies |
| `manage-tech-debt` | Identify, prioritize, and address technical debt |
| `write-runbook` | Create operational runbooks grounded in actual system state |
| `conduct-post-mortem` | Blameless incident analysis with architecture context |

## Installation

### Claude Code

```
/plugin marketplace add gjalla/gjalla-plugin
/plugin install gjalla@gjalla-plugin
```

### Cursor

Install from the [Cursor Marketplace](https://cursor.com/marketplace), or add the repo manually.

### With gjalla MCP server (optional)

The plugin includes MCP server config that auto-configures the gjalla MCP server. For it to work:

```bash
pip install gjalla[mcp]
gjalla setup
```

Without the MCP server, all skills still work, they just won't have access to the curated architecture and configured rules.

## File formats

The `references/` directory contains specs and examples for:

- **gjallastate** — declarative architecture state (elements, connections, capabilities, tech stack, etc.)
- **gjallamap** — file-to-element evidence mapping
- **gjallarules** — principles, ADRs, and invariants
- **attestation** — commit attestation format

These are version-controlled, diffable, agent-readable descriptions of the state of your codebase.

## License

MIT
