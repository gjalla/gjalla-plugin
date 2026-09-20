# gjalla plugin

Observability and optimization for agentic engineering. You can't optimize what you don't understand. So the first part of the gjalla plugin is focused on observability... giving you the data you need to understand what your coding agents are spending their time and tokens doing.

This gives you the power to see what should be discoverable as a durable memory, what should be stored as a skill, what rules should be enforced, etc... you can only optimize after you understand.

## Getting started

```bash
pip install gjalla
gjalla auth login       # browser-backed auth, one command
gjalla setup            # link a project + install full agent guidance
```

`gjalla setup` installs detailed agent instructions locally. The plugin provides bootstrap orientation; setup delivers the depth.

## Observability

The core plugin gives you the data: hooks that record what your coding agents are doing, session by session, so you can see where time and tokens actually go — before you try to optimize anything.

## Optimization

The MCP server gives your agent durable memory. gjalla's job is getting the right piece of that memory into the right mechanism — a skill, a discoverable memory, a rule, a hook — so it shows up at the right time in the right format, instead of being re-discovered every session. Ellie is drafting this, will be up soon :)

The rest of the plugin is what makes that possible:

- **Bootstrap agent instructions** — orients the agent on what gjalla is, how to start, and which tools matter most
- **9 skills** — engineering workflows for planning, review, cleanup, debugging, and onboarding
- **6 commands** — `/gjalla-context`, `/gjalla-review`, `/gjalla-impact`, `/gjalla-attest`, `/gjalla-setup`, `/gjalla-log`
- **MCP server** — connects to [gjalla](https://gjalla.io) for live architecture context, change history, impact analysis, and rule enforcement
- **Reference docs** — annotated examples for gjallastate, gjallamap, gjallarules, and attestation file formats

### Skills

| Skill | What it does |
|-------|-------------|
| `gjalla-spec` | Define what should be true before writing code |
| `gjalla-spec-review` | Review a spec from multiple expert perspectives |
| `gjalla-breakdown` | Break a feature into sized, dependency-ordered task waves |
| `gjalla-code-review` | Review a code change for ship-readiness before merge |
| `gjalla-cleanup-audit` | Find dead code, drift, and cleanup opportunities |
| `gjalla-test-audit` | Find tests that give false confidence |
| `gjalla-debug` | Systematic root-cause debugging |
| `gjalla-onboard` | Cold-start orientation — architecture, rules, changes, memories |
| `gjalla-prepare-commit` | Stage a clean, atomic commit with attestation |

### Key MCP tools

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
