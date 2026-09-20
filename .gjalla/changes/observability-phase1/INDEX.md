# Observability Phase 1 — brief index and hand-off protocol

Author: Claude (Cowork planning session with Ellie), 2026-09-19. The same file is
in all three repos under `.gjalla/changes/observability-phase1/`. The plan with
acceptance criteria is in the shared doc; the live progress bar is the
"gjalla Observe · Phase 1" page; tracker step numbers below refer to it.

## Briefs, in hand-off order

Three lanes run in parallel. Within a lane, hand off the next brief only after
Claude has verified the previous one.

| Brief | Repo | Branch | Tracker steps | Starts when |
| --- | --- | --- | --- | --- |
| B1 `COWORK-B1-web-schema-route-store.md` | am-i-doing-it | `feat/observability-ingest` off `dev` | 4–7 | now |
| B3 `COWORK-B3-aas-module-port.md` | agentic-analysis-service | `feat/observability-session-update` off `dev` | 11–12 | now |
| B6 `COWORK-B6-cli-parser-uploader.md` | gjalla-precommit | `feat/observability-collector` off `dev` | 15–16 | now |
| B2 `COWORK-B2-web-rollup-dispatch-read.md` | am-i-doing-it | same branch as B1 | 8–10 | B1 verified |
| B4 `COWORK-B4-aas-handler-parity.md` | agentic-analysis-service | same branch as B3 | 13–14 | B3 verified and B2 verified (needs the job dispatch and a local dev with uploaded sessions) |
| B7 `COWORK-B7-cli-hooks-scan-plugin.md` | gjalla-precommit + gjalla-plugin | same branch as B6; `feat/core-plugin` off `main` in gjalla-plugin | 17–20 | B6 verified and B1 verified (needs the route on local dev) |
| B5 `COWORK-B5-web-sessions-view.md` | am-i-doing-it | `feat/observability-sessions-ui` off `feat/observability-ingest` | 21–23 | B2 and B4 verified |
| Gate B | Ellie's machine | — | — | B4, B5, B7 verified: corpus → local dev → matching numbers → visible |
| B8, B9 (dogfood; public repo + SETUP) | written after Gate B | | 24–27 | |

## Re-cut, 2026-09-20 (Ellie): no jobs in Phase 1

Phase 1 is collection, classification and front-end aggregation, all in the
web service. Classification comes from the attestation the agent writes at
commit time (the CLI's PostToolUse commit-capture hook, now shipped by the
plugin as its fourth hook), not from a per-session analysis job. So:
the per-delta `session-update` dispatch, the wire contract and the
`analysis` column are removed (B2.3); the analysis service's PR #218 is
parked, not merged (B3/B4 stay on their branch as a future admin-dispatched
job); tracker steps 9 and 11–14 are out of Phase 1. The follow-up briefs,
in order:

| Brief | Repo | Branch | Starts when |
| --- | --- | --- | --- |
| B2.3 `COWORK-B2.3-web-no-dispatch-attestations.md` | am-i-doing-it | `feat/observability-ingest` (#432) | now |
| B7.4 `COWORK-B7.4-cli-commit-capture-codex.md` | gjalla-precommit | `feat/observability-collector` (#64) | now |
| PLUGIN-2 `COWORK-PLUGIN-2-commit-capture-hook.md` | gjalla-plugin | `feat/core-plugin` (#1) | Claude Code row now; Codex row after B7.4 |
| B5.1 `COWORK-B5.1-ui-attestation-panel.md` | am-i-doing-it | `feat/observability-sessions-ui` (#433) | after #433 is rebased on B2.3 |
| B5.2 `COWORK-B5.2-ui-team-summary.md` | am-i-doing-it | same branch | after B5.1 |

`ORCHESTRATOR-phase1-close.md` (root of `~/devspace/gjalla`) runs these lanes on Ellie's Mac and reports once; the release captain then re-readies the PRs.

`event-schema-v2.md` in the same folder is the frozen contract every brief
depends on. If a brief and the schema disagree, the schema wins; stop and say so.

## What the implementor agent does

1. Read the brief and `event-schema-v2.md` in full. Copy nothing, summarise
   nothing, follow it as written. Ambiguous or impossible → stop and ask Ellie.
2. Create or check out the branch named in the brief. Commit the brief file.
3. Do the sections in order. Each section's acceptance criteria are the
   definition of done; write the tests the criteria describe.
4. Run the repo's full test suite and the repo's pre-commit gate before
   reporting.
5. Write `.gjalla/changes/observability-phase1/findings-<brief>.md` (for
   example `findings-B1.md`): files changed, the numbers each acceptance
   criterion asked for, test counts before and after, anything not done,
   stated plainly. Commit it on the branch.

## What Claude verifies before the next brief is handed off

Claude reads the branch through the connected folder: the diff against the
base, the findings file, and the test output. Claude checks each acceptance
criterion against the code, not the findings text, and either marks the
tracker steps done or sends back a short list of what is short. Nothing merges
to `dev` until Gate B.
