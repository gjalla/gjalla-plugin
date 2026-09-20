# gjalla (OpenClaw) — no hook surface yet

This directory used to ship a full plugin (commands, skills, a Claude-Code-shaped
`hooks.json`). Removed: "OpenClaw" (`~/devspace/gjalla/openclaw-social-agents`,
`~/.openclaw`) is Ellie's self-hosted, Dockerized multi-agent stack running local
Ollama models for social content automation — it is not a packaged coding agent,
it isn't in the event schema's harness enum (`claude-code | codex-cli | cursor |
devin | custom`), and it has no documented or discoverable lifecycle-hook system
to bundle a plugin's `hooks.json` into. There is nothing here for the three
collector hooks to attach to.

`gjalla scan --upload` is the fallback for harnesses without a hook surface,
but as shipped it only globs `~/.claude/projects/*/*.jsonl` and
`~/.codex/sessions/**/*.jsonl` — it does not know about OpenClaw's transcript
location, so it won't pick up OpenClaw sessions either, today. There is no
telemetry path for OpenClaw yet. Revisit this directory if OpenClaw grows a
real hook/plugin API, or extend `gjalla scan`'s discovery to OpenClaw's
transcript paths.
