# Gjalla State Files: Design & Usage

Gjalla uses three declarative files to represent a software system, plus an attestation format for tracking changes. Together they answer four questions:

| File | Question |
|---|---|
| **gjallastate** | What is this software? |
| **gjallamap** | Where is it implemented? |
| **gjallarules** | What must hold true? |
| **attestation** | What changed and why? |

Each layer is a different resolution of the same reality. Mismatches between layers — a rule that references an element the map can't find evidence for, an attestation that claims no architecture change but the state diff shows one — are the interesting part. That's what needs review.

## Why These Files Exist

AI coding agents have no long-term memory. They can't remember your architecture, your team's rules, or why you made a decision six months ago. Every session starts from zero.

These files solve that. They give agents (and humans) a structured, diffable, version-controlled source of truth about the system — without reading every file in the codebase.

The design draws from Terraform's state model: declare what exists, track evidence, enforce constraints, and attest to changes. The files are YAML because YAML diffs cleanly in PRs, is human-readable, and is trivially parseable by agents.

## The Three Layers

### gjallastate — Structure + Facts

Declares what the system is. Architecture elements, data model, capabilities, tech stack, API surface, external services. Every entry carries **facts** — declarative assertions about behavior, not implementation details.

```yaml
architecture:
  api-server:
    type: container
    description: Express.js API server handling all REST endpoints
    facts:
      - Handles authentication via Clerk middleware
      - Uses Drizzle ORM for database access
      - Runs on port 3001 in development
```

Facts are the key innovation. They capture the kind of knowledge that lives in a senior engineer's head — "this service retries failed charges up to 3 times," "orders are soft-deleted, never hard-deleted" — and make it available to any agent working on the code.

**Design decisions:**
- **Stable descriptive keys** (e.g. `api-server`, not UUIDs) so diffs are human-readable
- **Flat structure within categories** — elements are siblings, not nested trees. Parent-child via `parent` field. This keeps diffs isolated to one block.
- **Relationships are inline** on elements, not a separate section. An element's connections are part of its declaration.
- **No file references** — that's what gjallamap is for. Separating structure from evidence keeps each file focused and independently useful.

See [example-gjallastate.yaml](example-gjallastate.yaml) for a complete annotated example.

### gjallamap — Code Evidence

Maps every gjallastate entry to the files and methods that implement it. If gjallastate is the blueprint, gjallamap is the address book.

```yaml
architecture.api-server:
  - file: server/index.ts
  - file: server/app.ts
    methods: [createApp, configureMiddleware]

architecture.payment-service.relationships.stripe-api:
  - file: server/services/payment.ts
    methods: [callStripeAPI]
```

**Design decisions:**
- **Flat dot-path keys** (e.g. `architecture.api-server`, not nested YAML) — adding or removing a mapping is a clean, isolated diff. No indentation cascades.
- **Keys reference gjallastate entries** — every map key corresponds to a state entry. Missing coverage (state entry with no map entry) is a gap worth investigating.
- **File-level is the minimum, method-level is ideal** — `methods` is optional. Even file-level mapping is enormously useful for agents deciding what to read.
- **Relationships get their own map entries** — `architecture.X.relationships.Y` maps to the code that implements the connection, not just the endpoints.

The map enables deterministic lookups: "which architecture elements does `server/routes/payments.ts` belong to?" No LLM needed — just reverse the index.

See [example-gjallamap.yaml](example-gjallamap.yaml) for a complete annotated example.

### gjallarules — Constraints

What must hold true. Principles your team follows, architectural decisions you've made (ADRs), invariants that can't break.

```yaml
principles:
  separation-of-concerns:
    description: Route handlers must not access the database directly
    status: active
    scope:
      - architecture.api-server
    evidence:
      - pattern: "no imports from server/db/* in server/routes/*"
        type: import_check
```

**Design decisions:**
- **Three rule types** with different semantics:
  - **Principles** — ongoing guidelines ("always do X")
  - **ADRs** — point-in-time decisions with context ("we chose X because Y")
  - **Invariants** — hard constraints ("X must never happen")
- **Scope references gjallastate entries** — "which parts of the system does this rule govern?" This creates the chain: rule -> state entries -> map entries -> code.
- **Evidence enables deterministic checking** — rules with `evidence` entries (import_check, code_pattern, file_presence) can be verified without an LLM. Rules without evidence require human or agent judgment.
- **Status tracks lifecycle** — active, deprecated, superseded. Rules evolve; the file tracks that.

See [example-gjallarules.yaml](example-gjallarules.yaml) for a complete annotated example.

## Attestations — Change Accountability

When an agent (or human) commits code, they write an attestation declaring what changed and why. The attestation covers all eight primitives (architecture, data model, data flows, rules, capabilities, API surface, external dependencies, tech stack) and includes rule compliance status.

```yaml
changes:
  architecture:
    elements:
      - name: "web-api"
        change: "modified"
        fact_changes:
          add: ["Enforces token-bucket rate limiting"]
    connections:
      - source: "web-api"
        target: "redis"
        change: "added"
  data_model:
    changed: false
```

**Design decisions:**
- **All eight primitives are required** — even if just `changed: false`. This forces the agent to consider every dimension, not just the one it was focused on.
- **Fact changes are explicit** — `add`, `update`, `remove` for each element. This makes the state diff predictable: the attestation says what the next gjallastate should look like.
- **Rule compliance is self-reported** — the agent checks rules and reports compliant/not-applicable/remediated/needs-review. The system can then verify against the actual diff.
- **Provenance tracks origin** — was this change from a spec, a ticket, a bug fix, or ad-hoc? This creates traceability from business intent to code change.
- **Summary requires reasoning** — not "added rate limiting" but "token-bucket rate limiting on auth endpoints protects against credential-stuffing; chose gateway-level enforcement over per-service to avoid duplicating config." The why matters more than the what.

See [example-attestation.yaml](example-attestation.yaml) for a complete annotated example.

## How Agents Use These Files

### Orientation (starting a new task)
Read gjallastate to understand the system. Read gjallarules to know the constraints. The agent now has the context a senior engineer carries in their head.

### Before editing a file
Look up the file in gjallamap (reverse index) to see which architecture elements it belongs to. Read the facts and rules scoped to those elements. Now the agent knows what it's touching and what constraints apply.

### During implementation
Match codebase conventions visible in gjallamap (what patterns exist in sibling files). Respect rules scoped to the elements being modified. Use facts to avoid breaking implicit contracts.

### Before committing
Write an attestation covering all eight primitives. Check every applicable rule. Report compliance status. Explain the reasoning. The pre-commit hook validates the attestation exists and the diff hash matches.

## How These Files Are Produced

Gjalla's analysis pipeline (LLM agents analyzing the codebase) generates the initial gjallastate and gjallamap. Rules come from the team via the gjalla platform or CLI. Attestations are written per-commit by the coding agent.

After initial generation, the files are maintained incrementally: each commit updates only the entries that changed. The attestation documents those changes, creating a complete audit trail.

## The Verification Chain

The four files create a verification chain:

```
gjallarules (what must hold)
    |
    v  scope references
gjallastate (what exists)
    |
    v  dot-path keys
gjallamap (where it's implemented)
    |
    v  file paths
actual code
```

At each link, you can check consistency:
- Does the code match what the map says?
- Does the map cover what the state declares?
- Do the state entries satisfy the rules?
- Does the attestation match the actual diff?

Mismatches at any level are drift — and drift is what gjalla is designed to detect and resolve.
