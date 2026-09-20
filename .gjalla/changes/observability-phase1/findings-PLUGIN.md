# Findings — PLUGIN: collection-only, three hooks per harness

Branch `feat/core-plugin`, repo `gjalla-plugin`.

## Final tree

```
claude/
  .claude-plugin/plugin.json   (name gjalla, v0.1.0, hooks -> ./hooks/hooks.json)
  hooks/hooks.json             (SessionStart, Stop async, SessionEnd)
  README.md
codex/
  .codex-plugin/plugin.json    (name gjalla, v0.1.0, hooks -> ./hooks/hooks.json)
  hooks/hooks.json             (SessionStart, Stop async, SessionEnd timeout:3)
  README.md
cursor/
  .cursor-plugin/plugin.json   (name gjalla, v0.1.0, hooks -> ./hooks/hooks.json)
  hooks/hooks.json             (sessionStart, stop timeout:5, sessionEnd timeout:3 — {version:1,...} wrapper)
  README.md
openclaw/
  README.md                    (README-only stub, no hooks.json)

.claude-plugin/marketplace.json   -> ./claude only
.cursor-plugin/marketplace.json   -> ./cursor only
PLUGIN_SYNC.md                    -> one rule + scripts/check-hooks.sh
README.md                         -> collection-only framing, what's sent/not sent, per-harness table
scripts/check-hooks.sh            -> new, greps all hooks.json for `gjalla hook <name>`, fails on drift
```

`claude-core/` was promoted into `claude/` (deleted `claude-core/` after
copying). The old `claude/` tier (skills, 6 commands, `.mcp.json`,
`references/`, `CLAUDE.md`, the PostToolUse attestation hook) is gone.
`cursor/rules/`, `cursor/mcp.json` gone. `openclaw/` reduced from a full
plugin (commands, skills, CLAUDE.md, hooks.json, `.claude-plugin/`,
`.mcp.json`) to just a README.

`scripts/sync-skills.sh` deleted — dead now that no plugin directory ships
`skills/`. Left `scripts/gjalla-attestation-check.sh` and
`scripts/gjalla-post-commit-upload.sh` alone — those are this repo's own
dev-time git hooks, not plugin-distributed content, out of scope for this
brief.

`DISTRIBUTION_CHECKLIST.md` was untracked and already stale (referenced
the old 6-skill/6-command plugin and a 0.7.0 PyPI version); deleted rather
than updated — nothing in it was still actionable for the collection-only
shape. `claude-v01-backup/` and `cursor-v01-backup/` were already removed
in an earlier working session on this branch (confirmed gone, in git
history as the brief states).

## The Codex stdin field check (brief section 2, required before building)

Checked `gjalla_precommit/commands/hook_cmd.py` against the confirmed
Codex hook payload shape (`learn.chatgpt.com/docs/hooks`, fetched and
independently verified against the raw HTML — not taken on faith, since
the first AI-summarized fetch read suspiciously like Claude Code's own
docs; the raw page confirmed `SessionStart`/`SessionEnd`/`Stop`/
`PreToolUse`/`PostToolUse` event names, `CLAUDE_PLUGIN_ROOT`/
`CLAUDE_PLUGIN_DATA` as real legacy env var aliases Codex sets, and the
"SessionEnd/Interrupt default 1s, max 3s; everything else defaults 600s"
timeout split verbatim):

- `session_id`: Codex sends `session_id` (snake_case). `_resolve_session_id`
  checks `payload.get("session_id")` first. **Matches, no fix needed.**
- `transcript_path`: Codex sends `transcript_path` (snake_case).
  `_resolve_transcript_path` checks `payload.get("transcript_path")` first.
  **Matches, no fix needed.**
- `harness` detection: `_harness_from_payload` reads
  `payload.get("agent") or payload.get("harness")`, lowercases it, and
  checks for the substring `"codex"` — else defaults to `"claude-code"`.
  **Codex's documented common hook fields are `session_id`,
  `transcript_path`, `cwd`, `hook_event_name`, `model`,
  `permission_mode`, and (turn-scoped) `turn_id` — there is no `agent` or
  `harness` key anywhere in the payload.** None of the three `gjalla hook
  *` commands accept a CLI flag either (checked: no `click.option` on any
  of `turn_end`/`session_end`/`session_start`), so there is no way to
  supply the harness from the plugin side. **Every session collected
  through `codex/`'s hooks will be posted and tagged `harness:
  "claude-code"` until this is fixed.**

This is a CLI bug, not a plugin bug, per the brief's own instruction
("the fix goes in the CLI ... not in the plugin; say so and stop"). Not
fixed here. Flagged in `codex/README.md`'s "Known gap" section and needs
a fix on `feat/observability-collector` in `gjalla-precommit` — simplest
fix is probably a `--agent codex-cli` option on the three hook commands,
set directly in `codex/hooks/hooks.json`'s `command` string, rather than
trying to infer it from Codex's payload.

**Same bug found independently for Cursor** while verifying its hook
schema (not asked for by this section, but found doing the equivalent
check): Cursor's payload also has no `agent`/`harness` field, so Cursor
sessions will be mistagged `claude-code` too. Additionally, Cursor's
`stop` hook payload identifies the session via `conversation_id`, not
`session_id` — `_resolve_session_id` won't find it, so a `stop`-triggered
post may silently drop for want of a session id (though `sessionStart`/
`sessionEnd` do send `session_id` and are unaffected). Both flagged in
`cursor/README.md`, not fixed here, same reasoning.

## Cursor and OpenClaw verdicts

**Cursor: keep, with hooks.json rewritten — it was wrong.** The existing
`cursor/hooks/hooks.json` on this branch was a byte-copy of Claude Code's
PascalCase `SessionStart`/`Stop`/`SessionEnd` schema. Fetched Cursor's
actual hooks reference (`cursor.com/docs/agent/hooks`) and plugin
reference (`cursor.com/docs/reference/plugins`, reached via
`cursor.com/llms.txt` after `cursor.com/docs/hooks.md` and
`cursor.com/docs/reference/plugins.md` both 404'd): Cursor's hook
config is `{"version": 1, "hooks": {...}}` with **camelCase** event names
— `sessionStart`, `stop`, `sessionEnd` — not the PascalCase Claude Code
uses. That old file would silently never have matched any Cursor event.
Rewrote it correctly. Cursor Plugins (`.cursor-plugin/plugin.json`) do
support a `hooks` field pointing at `hooks/hooks.json` (confirmed
directly from the plugin reference doc, with a worked example matching
this repo's existing `plugin.json` shape almost field-for-field) — the
existing `cursor/.cursor-plugin/plugin.json` was just missing the `hooks`
key entirely, so even a correct `hooks.json` sitting next to it would
never have been loaded. Added it. `sessionStart`/`sessionEnd` are
fire-and-forget by Cursor's own design (no `async` flag exists in its
hook schema at all); `stop` is synchronous, so `turn-end` will briefly
hold up the end of each Cursor turn — capped with `"timeout": 5`, noted
in `cursor/README.md`.

**OpenClaw: cut to a README, no hooks.json.** Read
`~/devspace/gjalla/openclaw-social-agents` (SETUP.md, `director/AGENTS.md`,
no hook-related code anywhere in a full-repo grep for "hook") and
`~/.openclaw/openclaw.json`. OpenClaw is Ellie's self-hosted, Dockerized
multi-agent stack (`agents.list`: main/milo/scout/director) running local
Ollama models (`gemma4`) for social-content automation — a personal
system, not a distributed coding-agent product. It: (a) isn't a packaged
coding agent at all — its agents draft/render/publish social video, they
don't write code; (b) isn't in `event-schema-v2.md`'s harness enum
(`claude-code | codex-cli | cursor | devin | custom`); (c) has no
documented or discoverable lifecycle-hook mechanism in either repo — zero
hits for "hook" outside unrelated files (an HTML template literally named
`kinetic-hook.html`). There is nothing to bundle a `hooks.json` into.
Reduced the directory to a README stating this and correcting an
overclaim I almost shipped (that `gjalla scan --upload` covers OpenClaw
as a fallback — checked `findings-B7.md`: it only globs
`~/.claude/projects/*/*.jsonl` and `~/.codex/sessions/**/*.jsonl`, neither
of which is where OpenClaw would write transcripts even if it had them in
a compatible format). Said plainly in the README that there is no
telemetry path for OpenClaw yet.

## Acceptance — what was and wasn't run

Not run: none of the four acceptance observations (fresh Claude Code
profile install, fresh Codex plugin install + trust + timing, Cursor
verification) were exercised end-to-end. This environment has no way to
launch a real Claude Code/Codex/Cursor GUI or CLI session into a fresh
profile, install this plugin from the local marketplace path, or watch
`~/.gjalla/collect/` advance against a live network — same limitation
B7's findings already hit and stated plainly rather than fabricated
timings for. What *was* checked:

- All six `hooks.json`/`plugin.json`/`marketplace.json` files parse as
  valid JSON (`python3 -m json.load` on each).
- `scripts/check-hooks.sh` passes: all three `hooks/hooks.json` invoke
  exactly `gjalla hook session-start`, `gjalla hook turn-end`, `gjalla
  hook session-end` and nothing else.
- `claude/`, `codex/`, and `cursor/` each contain exactly a manifest, a
  `hooks/hooks.json`, and a `README.md` — no skills, no commands, no
  `.mcp.json`, no `references/`, no attestation hook, no `CLAUDE.md`
  (confirmed by directory listing, shown in "Final tree" above).
- The hook-event names and payload field names for Codex and Cursor were
  checked against their real, current docs (fetched and spot-verified
  against raw HTML, not taken from the AI-summarizer's first pass
  unverified — see the Codex section above for why that mattered), not
  assumed from Claude Code's shape.

Needs Ellie, same four items as B7 already flagged plus the two new ones:

1. Install `claude/` into a fresh Claude Code profile; run two turns;
   exit. Confirm no startup dialogs, session-start instructions appear,
   `~/.gjalla/collect/` advances, and a killed network fills the outbox
   and the next session drains it.
2. Install `codex/` the way Codex installs a plugin; run `/hooks` and
   trust the three `gjalla` entries (they will *not* be pre-trusted);
   confirm hooks actually fire (per `openai/codex#46210`, `codex exec`
   silently skips untrusted hooks with no error) and that `SessionEnd`
   completes inside its 3s budget.
3. Fix the CLI harness-detection gap (no `agent`/`harness` field in
   either Codex's or Cursor's hook payload) on
   `feat/observability-collector` in `gjalla-precommit`, then re-check
   that a Codex-collected session actually lands tagged `codex-cli` —
   right now it will land tagged `claude-code`.
4. Fix the CLI's Cursor `stop`-hook session-id resolution (Cursor sends
   `conversation_id` on `stop`, not `session_id`) on the same branch.
5. Install `cursor/` for real and confirm the rewritten camelCase
   `hooks.json` actually fires — I could not run Cursor to verify this,
   only cross-check it against Cursor's own docs.

## Not done, stated plainly

1. No acceptance criterion was run against a live installed harness —
   documentation- and static-check-verified only, per the notes above.
2. The Codex and Cursor CLI-side harness-detection/session-id gaps found
   above are not fixed (out of scope for this repo/branch, per the
   brief); only documented in each plugin's README and here.
3. `gjalla scan --upload`'s discovery globs don't cover OpenClaw (or any
   non-Claude-Code/Codex harness) — noted in `openclaw/README.md`, not
   changed (that command lives in `gjalla-precommit`).

## PLUGIN-2: the fourth hook, commit capture (sections 1 and 3)

Branch `feat/core-plugin`, on top of 0658e31. Section 2 (Codex row) not
done here: it waits on CLI B7.4 and is a separate lane.

### Files changed

- `claude/hooks/hooks.json` — added `PostToolUse`, matcher `Bash`, command
  = `COMMIT_CAPTURE_COMMAND` from
  `gjalla-precommit/gjalla_precommit/agents/claude_code.py` with ` --user`
  removed. Taken from the source by importing the module and stripping the
  flag, then asserted equal to the JSON value (not retyped). Other three
  entries unchanged.
- `scripts/check-hooks.sh` — still requires the identical three collector
  commands in all three `hooks.json`; now also requires exactly one row in
  `claude/hooks/hooks.json` equal byte-for-byte to the commit-capture
  command, and zero `gjalla attest` rows in `codex/` and `cursor/` until
  section 2 applies.
- `scripts/check-hooks-test.sh` — new. Copies the tree to a temp dir,
  mutates it, asserts `check-hooks.sh` passes on the shipped tree and fails
  on: missing Claude row, wrong `--agent`, `--user` present, edited `sh -c`
  wrapper, Codex carrying the row, renamed Cursor collector command, missing
  `hooks.json`. Force-added (`/scripts/` is gitignored, same as
  `check-hooks.sh`).
- `README.md` — "what it collects" gains "commits, with the attestation
  the agent writes for them (task type, summary)"; hook table gains the row
  (marked Claude Code only); one sentence on double firing with
  `gjalla setup hooks`.
- `claude/README.md` — "Four hooks"; table gains the row; collects
  sentence; wrapper behaviour and double-firing sentence.
- `.claude-plugin/marketplace.json` — description "three hooks" → "four
  hooks" (not in the brief; the old text would have been wrong).
- `codex/README.md`, `codex/hooks/hooks.json`, `cursor/*`,
  `PLUGIN_SYNC.md` — unchanged. PLUGIN_SYNC's one rule (three collector
  commands identical everywhere) still holds and is still what the script
  enforces for the collector set.
- `.gjalla/changes/observability-phase1/findings-PLUGIN.md` — was untracked
  in the main checkout (`.gjalla/changes/` is gitignored); force-added to
  the branch with this section appended.

### Checks run

- All three `hooks.json` and `marketplace.json` parse as JSON.
- `claude/hooks/hooks.json` `PostToolUse[0].matcher == "Bash"` and command
  `== COMMIT_CAPTURE_COMMAND.replace(" --user", "")`: match.
- `scripts/check-hooks.sh`: OK before and after.
- `scripts/check-hooks-test.sh`: 8 passed, 0 failed.
- Test counts: before 0 (no test in repo, one parity script); after 8 drift
  cases in `check-hooks-test.sh`.
- Pre-commit gate: the repo's git hook runs
  `scripts/gjalla-attestation-check.sh`, which is untracked and needs
  `.gjalla/.platform/config.yaml`; both were absent in this worktree
  (gitignored), so the gate would have exited 0 without checking. Copied
  both from the main checkout (still untracked) so the attestation gate
  ran for real on this commit.

### Not done, stated plainly

1. The acceptance run (fresh Claude Code profile, plugin from the local
   marketplace path, commit without attestation, observe nudge and
   `gjalla attest add --commit <sha>`, see it in Observe > Sessions or in
   `gjalla sync` output) was not run: no way to launch a fresh Claude Code
   profile from this session. Same limitation as the sections above.
   Needs Ellie.
2. Section 2 (Codex row) — separate lane, waits on B7.4.

## PLUGIN-2: section 2, the Codex row (plus the section 3 parts it makes apply)

Branch `feat/core-plugin`, on top of 4f7e6be. B7.4 (gjalla-precommit
`feat/observability-collector`, 3db7322) found Codex has `PostToolUse`,
matches shell calls as `Bash`, and sends the command in
`tool_input.command`, so section 2 applies: Codex gets the row.

### Files changed

- `codex/hooks/hooks.json` — added `PostToolUse`, matcher `Bash`, command
  = `COMMIT_CAPTURE_COMMAND` from `gjalla_precommit/agents/claude_code.py`
  with ` --user` removed and `--agent claude-code` → `--agent codex-cli`.
  Derived from the imported source, asserted against the Claude row, not
  retyped. The other three entries unchanged. No `timeout` on the row:
  Codex's default for events other than SessionEnd/Interrupt is 600s
  (B7.4 / findings-PLUGIN above), and the wrapper exits immediately on
  anything but a `git commit`.
- `scripts/check-hooks.sh` — the expected command set is now four for
  Claude Code and Codex: exactly one row in `codex/hooks/hooks.json`
  byte-equal to the Claude row with `--agent codex-cli` substituted; still
  zero `gjalla attest` rows in `cursor/`; the three collector commands
  still identical everywhere.
- `scripts/check-hooks-test.sh` — the "codex carrying a row before section
  2" case is gone; replaced by: Codex missing the row, Codex wrong
  `--agent`, Codex `--user` present, Cursor carrying a row (added beside
  the collector commands, so it trips the attest branch, not the collector
  one). 8 → 11 drift cases.
- `codex/README.md` — "Four hooks"; table gains the row (and now shows the
  `--harness codex-cli` flags the file actually carries); "what it
  collects" sentence with "commits, with the attestation the agent writes
  for them (task type, summary)"; wrapper behaviour, the Codex payload
  facts with the doc reference from findings-B7.md
  (`learn.chatgpt.com/docs/hooks`), and the double-firing sentence;
  `/hooks` trust step says four entries.
- `README.md` — hook-table row no longer "Claude Code only": "(Claude Code,
  Codex)", command `--agent <claude-code|codex-cli>`; intro sentence
  "Claude Code and Codex wire a fourth".
- `claude/*`, `cursor/*`, `PLUGIN_SYNC.md`, marketplace files — unchanged.
  PLUGIN_SYNC's one rule (three collector commands identical everywhere)
  still holds.

### Checks run

- All three `hooks.json` parse as JSON.
- `codex/hooks/hooks.json` `PostToolUse[0].matcher == "Bash"`, command ==
  Claude row with `--agent codex-cli`; Claude row still ==
  `COMMIT_CAPTURE_COMMAND.replace(" --user", "")`.
- `scripts/check-hooks.sh`: OK before (three collector + Claude row) and
  after (three collector + Claude and Codex rows).
- `scripts/check-hooks-test.sh`: before 8 passed, 0 failed; after 11
  passed, 0 failed.
- Pre-commit gate (`scripts/gjalla-attestation-check.sh` via the repo's
  git hook, config and script present untracked from the previous lane):
  ran on this commit.

### Not done, stated plainly

1. The acceptance run for Codex (install the plugin, trust the four
   entries in `/hooks`, commit without an attestation, observe the nudge
   and the classification landing) was not run: no way to launch Codex
   from this session. Same limitation as the Claude Code row. Needs Ellie.
