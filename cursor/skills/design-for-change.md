# Design for Change

Senior engineers don't just design for the current requirements — they design for a version
of the system that doesn't exist yet. Not speculatively (that's over-engineering), but
informed by the trajectory they can see: the roadmap, the team's direction, the patterns
of growth in the data and traffic.

This isn't about predicting the future. It's about noticing which parts of your design are
likely to change and making those parts easy to change, while keeping the stable parts simple.
The skill is knowing the difference.

---

## Step 0: Load Roadmap and Architecture Context

Temporal design is only as good as your understanding of what's coming. Before speculating
about future change, check what's actually planned.

**If gjalla is available**, query these tools first:

- `get_context(scope="capabilities", status="proposed")` — load proposed/planned features.
  These are the concrete futures you should design for — not speculation, but actual
  roadmap items.
- `get_context(scope="capabilities", status="active")` — understand what exists today, so
  you can see which axes of change have already been accommodated and which haven't.
- `get_context(scope="rules")` — check for architecture principles about extensibility,
  modularity, or design-for-change. The team may have already codified how they want
  abstraction decisions to be made.
- `get_context(scope="architecture")` — understand the current architecture so you can
  see where abstractions exist and where they're missing.

**If gjalla is not available**, check roadmap documents, planning tickets, and team
conversations for context about what's coming.

---

## The Principle: Make Change Easy, Not Change Itself

The goal isn't to pre-build features that might be needed. That's YAGNI (You Ain't Gonna
Need It), and it creates complexity that's hard to maintain. Instead, the goal is to
structure your code so that *when* change comes, it's a small change — not a rewrite.

Good temporal design means:
- The parts most likely to change are isolated behind clear interfaces
- Adding a new variant of something (a new payment method, a new notification channel)
  requires adding code, not modifying existing code
- Configuration and behavior are separated so you can change one without touching the other
- Data models have room for evolution without breaking migrations

---

## How to Think Temporally

### 1. Identify the Axes of Change

For the feature you're building, ask: "What is most likely to change?"

Common axes of change:
- **Business rules** — pricing logic, eligibility criteria, approval workflows. These change
  constantly. Isolate them so they can be updated without touching infrastructure code.
- **External integrations** — third-party APIs, payment processors, notification services.
  These get swapped, versioned, and replaced. Hide them behind interfaces.
- **Scale dimensions** — number of users, data volume, request throughput. These grow.
  Don't hardcode limits or assume single-instance deployment.
- **Feature variants** — different behavior for different user tiers, regions, or A/B
  test groups. These multiply. Design for dispatch, not conditionals.
- **UI/presentation** — layouts, copy, styling. These change with every design review.
  Separate presentation from logic completely.

Conversely, identify what is *unlikely* to change:
- Core domain models (a user is a user, an order is an order)
- Fundamental data flows (requests come in, get processed, responses go out)
- Infrastructure choices (you're not switching databases next month)

The stable parts should be simple and direct. Don't add abstractions to things that aren't
going to change — that's complexity without purpose.

### 2. Apply the Right Level of Indirection

For each axis of change, choose the simplest mechanism that makes future change easy:

**Configuration** — for values that change without code changes:
```
# Good: business rules in config
MAX_CART_ITEMS = env.get("MAX_CART_ITEMS", 100)

# Unnecessary: abstracting something that won't change
class CartItemLimitStrategy(Protocol): ...
```

**Interfaces / protocols** — for behaviors that will have multiple implementations:
```
# Good: payment processor will likely be swapped or extended
class PaymentProcessor(Protocol):
    def charge(self, amount: Money) -> PaymentResult: ...

# Unnecessary: there's only one way to hash a password
class PasswordHasher(Protocol): ...  # Just use bcrypt directly
```

**Plugins / registries** — for open-ended extension points:
```
# Good: notification channels will keep getting added
NOTIFICATION_CHANNELS = {
    "email": EmailNotifier,
    "sms": SmsNotifier,
    "slack": SlackNotifier,
}

# Unnecessary: there are exactly two user roles and that won't change
ROLE_HANDLERS = { ... }  # Just use an if/else
```

### 3. Preserve Optionality in Data Models

Data models are the hardest thing to change later because data outlives code. When
designing schemas:

- **Use flexible types for things that will evolve.** A JSONB column for metadata is easier
  to extend than adding a new column for every attribute. But don't overuse this — queryable
  fields should be proper columns.
- **Include created_at and updated_at on everything.** You'll need them for debugging,
  auditing, and migration planning. Adding them later requires backfilling.
- **Use soft deletes for important entities.** A `deleted_at` column is much easier to
  recover from than a hard DELETE. This isn't always worth it, but for core business
  entities (users, orders, subscriptions), it usually is.
- **Version your data formats.** If you're storing structured data (JSON events, serialized
  objects), include a version field so you can migrate old data forward when the format
  changes.

### 4. Use Roadmap Awareness

If you have context about what's coming (from the user, from planning docs, from team
conversations), factor it into your design:

- **"We'll add international support next quarter."** Design your money handling with
  currency as a first-class concept now, even if you only support USD today. Adding
  currency later is an order of magnitude harder.
- **"We're planning to split this into microservices."** Draw clear module boundaries now.
  Use interfaces between the modules. Don't let database queries cross module boundaries.
- **"We'll need to support bulk operations."** Design your API to accept arrays from the
  start, even if v1 only processes single items.

But be disciplined about this. Only accommodate futures that are **likely and would be
expensive to retrofit.** "We might need to support 10 languages" is different from "we're
launching in Germany next quarter." The first is speculative; the second is actionable.

---

## The Over-Engineering Trap

The biggest risk with temporal design is building for futures that never arrive. Guard
against this by applying a simple test:

**"If I don't add this abstraction now, how hard will it be to add it later?"**

- If the answer is "I'd need to touch 3 files and it'd take an hour" → don't add it now.
  That's cheap enough to do when you actually need it.
- If the answer is "I'd need to migrate the database, update every consumer, and coordinate
  a multi-week rollout" → add the abstraction now. The cost of retrofitting is too high.

Most abstractions fall into the first category. The skill is identifying the few that fall
into the second.

---

## Output

This skill doesn't produce a standalone document. It shapes the decisions you make during
implementation. When you choose an approach *because* of future considerations, note it
briefly in a code comment or PR description:

```
// Using a NotificationChannel interface here because we know Slack and
// push notifications are on the roadmap for Q3. Makes adding new channels
// a one-file change rather than modifying the notification service.
```

These notes are valuable for future engineers (and agents) who might wonder "why is this
abstracted?" without the roadmap context you had.

### Attestation: Design Decisions

In the PR description, document the temporal design decisions and their justification:

```
## Design-for-Change Attestation

**Roadmap items considered**: [from get_context(scope="capabilities") — proposed features
that informed the design]
**Abstractions added**: [interfaces, extension points, config-driven behavior — and why]
**Abstractions NOT added**: [things you could have abstracted but didn't — and why the
retrofit cost is low enough to defer]
**Rules respected**: [architecture principles from get_context(scope="rules") about extensibility]
```

This makes the temporal reasoning visible. Without it, a future engineer sees an interface
and wonders if it's over-engineering. With it, they see the roadmap context that motivated it.
