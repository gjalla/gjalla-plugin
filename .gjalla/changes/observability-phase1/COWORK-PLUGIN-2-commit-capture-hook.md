# COWORK BRIEF PLUGIN-2: the fourth hook, commit capture

Author: Claude (Cowork planning session with Ellie), 2026-09-20. Repo
`gjalla-plugin`, branch `feat/core-plugin` (PR #1), on top of c3fa380.
Small. Waits for CLI B7.4 only for the Codex row; the Claude Code row can
go in now.

Ellie's decision: classification in Phase 1 comes from the attestation the
agent writes at commit time, so the plugin carries the commit-capture hook
after all, as its fourth hook. The CLI already implements it: `gjalla attest
add --from-hook --agent <harness>` reads the PostToolUse payload, ignores
anything but a successful `git commit`, records HEAD for the session, and
prints a nudge to write the attestation when there is none. So the plugin
is still collection only; this hook is how a commit gets collected with its
attestation.

## 1. `claude/hooks/hooks.json`

Add a `PostToolUse` entry with matcher `Bash` whose command is exactly the
`COMMIT_CAPTURE_COMMAND` in
`gjalla-precommit/gjalla_precommit/agents/claude_code.py` (the `sh -c`
wrapper that pre-filters for `git commit` and pipes the payload into
`gjalla attest add --from-hook --agent claude-code`), without the hidden
`--user` flag. Copy it from the source, do not retype it. The other three
entries are unchanged.

## 2. `codex/hooks/hooks.json`

After B7.4 lands: if it found Codex has `PostToolUse` with a shell command
in the payload, add the same row with `--agent codex-cli` (matcher per
Codex's docs). If B7.4 found it does not, Codex stays at three hooks and
the README says why, with the doc reference from `findings-B7.md`.

## 3. Parity check and docs

- `scripts/check-hooks.sh`: the expected command set is now four for
  Claude Code (and for Codex when section 2 applies). It must still fail on
  any drift.
- READMEs (root, `claude/`, `codex/`): the hook table gains the row; "what
  it collects" gains "commits, with the attestation the agent writes for
  them (task type, summary)". One sentence on double firing: a user who
  also ran `gjalla setup hooks` has the same row at user level; the CLI
  records a commit once, so both may be installed.
- `PLUGIN_SYNC.md`'s one rule is unchanged (identical command sets across
  harness directories).

## Acceptance

Fresh Claude Code profile with the plugin from the local marketplace path,
in a repo with gjalla configured: make a change, ask the agent to commit
without an attestation. Observe: the commit lands; the agent receives the
nudge; it writes `.gjalla/.commit-attestation.yaml` and runs `gjalla attest
add --commit <sha>`; the attestation shows on that session in Observe >
Sessions on dev after Gate B (before Gate B, `gjalla sync` output showing
the upload is enough). Log it in `findings-PLUGIN.md` under "PLUGIN-2".
Commit; the release captain re-runs #1.
