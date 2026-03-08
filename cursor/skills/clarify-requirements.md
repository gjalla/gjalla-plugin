# Clarify Requirements

Senior engineers read specifications differently than junior engineers. A junior reads what's
there. A senior reads what's *not* there. They notice the missing error states, the unspecified
edge cases, the assumptions that seem obvious today but will cause arguments next month.

This isn't pessimism — it's pattern recognition. After seeing enough features launch with
gaps, you develop an instinct for the questions nobody thought to ask. This skill makes that
instinct explicit and systematic.

---

## Step 0: Load Existing Context

Before analyzing gaps in the requirements, understand what already exists. Building
something that duplicates or conflicts with an existing capability is worse than missing
an edge case.

**If gjalla is available**, query these tools first:

- `get_context(scope="capabilities")` — load the existing feature catalog. Check whether
  the requested feature overlaps with, extends, or conflicts with anything already active
  or proposed. If a "proposed" capability matches the request, the team may already
  have opinions about how it should work.
- `get_context(scope="data_flows")` — trace how data currently moves through the system
  in the area you're about to change. This surfaces integration points the spec might
  not mention.
- `get_context(scope="rules")` — check for invariants or principles that constrain how
  this type of feature should be built (e.g., "all user-facing features must support
  multi-tenancy").

**If gjalla is not available**, scan for existing specs, feature docs, or planning
documents in the repo and Notion before starting the analysis.

---

## The Negative Space Framework

For any set of requirements, work through these dimensions. Each one surfaces a different
class of gap.

### 1. Failure Modes

For every described behavior, ask: "What happens when this doesn't work?"

- The spec says "send a notification when the order ships." What happens if the notification
  system is down? Does the shipment proceed? Does it retry? Is there a fallback?
- The spec says "validate the user's email." What happens when validation fails? What message
  does the user see? Can they retry? Is there a rate limit?
- The spec says "sync data from the external API." What happens when the API is slow?
  When it returns partial data? When it returns data in an unexpected format?

**The rule**: every verb in the spec ("send", "validate", "sync", "create", "update", "delete")
has a failure mode that probably isn't specified. Find them.

### 2. Boundary Conditions

For every value or quantity, ask: "What happens at the extremes?"

- The spec says "users can add items to their cart." How many items? Is there a limit?
  What happens at that limit?
- The spec says "display the user's name." How long can the name be? What about special
  characters, unicode, RTL text? What about users with no name set?
- The spec says "process transactions." What's the maximum amount? The minimum? What
  about zero? Negative values? Multiple currencies?

**The rule**: every noun in the spec ("items", "name", "transactions") has boundary conditions
that probably aren't specified. Find them.

### 3. State Transitions

For every entity that changes state, map the complete lifecycle:

- What states can it be in? (Not just the ones mentioned in the spec.)
- What transitions are valid? (And critically, which are *invalid*?)
- What happens if someone tries an invalid transition?
- Can an entity go backward in its lifecycle?
- What about concurrent state changes — can two people try to transition the same entity
  at the same time?

**The rule**: state machines have more states than the spec describes. The spec describes the
happy path. Find the other states.

### 4. Timing and Ordering

For any process with multiple steps, ask:

- Does the order matter? What happens if steps occur out of order?
- Can steps happen concurrently? What if two users trigger the same flow simultaneously?
- Are there time-sensitive aspects? Expiration, timeouts, rate limits?
- What happens between steps — is the intermediate state visible to other parts of the system?
- What about time zones, daylight saving time, leap years, month boundaries?

### 5. Actors and Permissions

For every action described, ask:

- Who can do this? Just the owner? Admins? Anyone?
- What about different user tiers or roles?
- Can this action be undone? By whom?
- What audit trail is needed?
- What about automated actors — background jobs, webhooks, API integrations?

### 6. Backwards Compatibility

For any change to existing behavior, ask:

- What currently works that might break?
- Are there existing API consumers depending on the current behavior?
- Is there cached data that assumes the old format?
- Are there scheduled jobs running against the old logic?
- What about mobile apps that can't be force-updated?
- Do database migrations need to be reversible?

### 7. Observability and Operability

Requirements almost never specify these, but you need answers:

- How will we know this is working correctly in production?
- How will we know when it breaks?
- How will we debug issues?
- What metrics, logs, or alerts do we need?
- Who gets paged when this breaks at 3am?

---

## Surfacing Questions Effectively

Once you've identified the gaps, present them in a way that makes decisions easy rather
than overwhelming. Group questions by impact:

### Critical (blocks implementation)

Questions where the answer fundamentally changes the architecture or approach. You can't
start coding without these answers.

Example: "The spec says 'sync data in real-time.' Does that mean sub-second latency
(requires WebSocket/streaming) or within-a-few-minutes (a polling job is fine)? These
are entirely different architectures."

### Important (need answers before shipping)

Questions where a reasonable default exists, but the product/business stakeholders should
confirm the choice.

Example: "The spec doesn't say what happens when a user tries to add a 101st item to their
cart. I'll default to showing an error message, but should we auto-remove the oldest item,
or expand the limit for premium users?"

### Minor (can decide during implementation)

Questions where any reasonable answer is fine and can be adjusted later without rework.

Example: "The spec doesn't specify the sort order for search results. I'll default to
relevance. Easy to change later."

---

## Output

Produce a requirements clarification document:

```
## Requirements Clarification: [Feature/Ticket Name]

### Critical Questions (blocks implementation)
1. [Question] — [why this matters]
2. [Question] — [why this matters]

### Important Questions (need answers before shipping)
1. [Question] — [recommended default if not answered]
2. [Question] — [recommended default if not answered]

### Minor Questions (will decide during implementation)
1. [Question] — [proposed default]
2. [Question] — [proposed default]

### Assumptions
[List of assumptions you're making based on context, existing patterns, or common sense.
These are things you believe to be true but that aren't explicitly stated.]
```

Share this with the user or stakeholders before starting implementation. The 20 minutes
spent identifying gaps saves days of rework.

### Cross-System Context

If the requirement touches areas documented across multiple systems, reference all of them:

- **Existing capabilities**: [from gjalla `get_context(scope="capabilities")` — what already exists]
- **Architecture constraints**: [from gjalla `get_context(scope="rules")` — what rules apply]
- **Data flow impacts**: [from gjalla `get_context(scope="data_flows")` — integration points affected]
- **Related discussions**: [from Slack — relevant threads where this was discussed]
- **Existing specs**: [from Notion — related design docs or brainstorms]

This cross-system view ensures the requirements clarification reflects the full context,
not just what's in the ticket.
