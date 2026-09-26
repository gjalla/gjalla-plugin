# gjalla plugin

Observability and agent capabilities for agentic engineering, in one
install: session/commit telemetry, memory (rules, skills, the gjalla MCP
server) and guardrails (commit gate context, enforcement) all ship in this
plugin, harness by harness, with no per-repo setup and nothing to run by
hand.

Each capability is a team-level switch in Team Settings (transcripts,
memory, guardrails) — not a per-repo or per-install choice. The plugin
itself never changes: what it does is decided by your team's policy, read
each time it runs. Turning memory off stops the instruction block and MCP
server; turning guardrails off stops the commit-gate context and
enforcement; both default on.

Skills still also come from `npx skills add gjalla/engineering` for
harnesses without a plugin surface.

## What it collects

A trimmed transcript, as ordered events: user and assistant text, tool
names and inputs, tool result sizes and error classes, commits, with the
attestation the agent writes for them (task type, summary), context
compactions, interrupts, and subagent boundaries.

## The hooks

Every supported harness wires the same three collection points to the
`gjalla` CLI (the collector). Claude Code and Codex wire a fourth, commit
capture, plus the guardrail rows (`gjalla rules context`) and the gjalla
MCP server:

| Event | Command | Notes |
|---|---|---|
| Session start | `gjalla hook session-start` | drains the outbox, sweeps missed deltas, and (memory on) injects the shared instruction block |
| End of each turn | `gjalla hook turn-end` | posts the turn's delta; async where the harness supports it |
| Session end | `gjalla hook session-end` | posts the final delta, `status: ended`, with the session's context makeup |
| Before `git commit`/`git push` (Claude Code, Codex) | `gjalla rules context --phase pre_commit\|pre_push` | guardrails on: injects the rules that apply; off: silent |
| Before every Bash command (Claude Code, Codex) | `gjalla rules context` (enforcement) | guardrails on: ask/deny for an enforced rule match; off: silent |
| After each `git commit` (Claude Code, Codex) | `gjalla attest add --from-hook --agent <claude-code\|codex-cli>` | `PostToolUse` on `Bash`, pre-filtered for `git commit`; records HEAD for the session and nudges the agent to write the attestation when there is none |

A user who also ran `gjalla setup hooks` has the same commit-capture row
at user level; the CLI records a commit once, so both may be installed.

Claude Code and Codex also register the gjalla MCP server
(`gjalla mcp serve --from-plugin`) for context, memory and rules tools --
empty (no tools registered) when memory is off, or when the repo already
has its own `gjalla` entry in `.mcp.json`.

The hooks post to wherever `gjalla auth login` configured
(`GJALLA_API_KEY`/`GJALLA_API_URL`, or the CLI's own config). This repo
carries no URL.

## Install per harness

| Harness | Directory | Status |
|---|---|---|
| Claude Code | [`claude/`](claude/) | plugin manifest + hooks + README |
| Codex CLI | [`codex/`](codex/) | plugin manifest + hooks + README — hooks need trusting via `/hooks`, see its README |
| Cursor | [`cursor/`](cursor/) | plugin manifest + hooks + README, but not yet listed in the marketplace — no Cursor transcript parser exists yet, hooks currently no-op, see its README |
| OpenClaw | [`openclaw/`](openclaw/) | README only — no hook surface to attach to, see its README |
| Devin | — | no local surface; a server-side pull through Devin's enterprise sessions API is planned, not built |

```
pip install gjalla
gjalla auth login
```

Then install the plugin for your harness (Claude Code: `claude plugin add
gjalla`; Codex: install then trust via `/hooks`, see `codex/README.md`).
Cursor isn't published to the marketplace yet — see `cursor/README.md`.

## License

MIT
