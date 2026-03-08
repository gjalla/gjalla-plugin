This plugin provides engineering skills and architecture context via gjalla.

Skills are always available. Use them when analyzing code, planning changes,
reviewing PRs, or preparing commits.

If gjalla MCP tools are available, use them to ground your analysis:
- get_context — orient in the project (architecture, rules, capabilities, tech stack)
- get_file_context — understand a file's architectural role before editing
- get_impact — check blast radius of uncommitted changes before committing
- prepare_attestation — create commit attestations (two-phase: draft then finalize)
- add_rule — add principles, ADRs, or invariants
- get_status — check if gjalla is configured correctly
- sync — refresh local cache from gjalla cloud
- setup — initialize gjalla in a repo

If MCP tools are not connected, skills still work — they just use manual analysis.

Reference files in references/ explain the gjalla state file formats
(gjallastate, gjallamap, gjallarules, attestation). Consult these when
you need to understand the data model.
