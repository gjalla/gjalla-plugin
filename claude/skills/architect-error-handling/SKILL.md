---
name: architect-error-handling
description: >
  Design error handling as a first-class concern, not an afterthought. Consider where failures
  get caught, what state they leave the system in, and what information flows to operators,
  callers, and users. Triggers on phrases related to errors, when you notice a critical piece
  of code without error handling, or when you're implementing a complex feature.
---

# Architect Error Handling

A junior engineer writes the happy path and then wraps it in a try-catch. A senior engineer
designs the error handling *simultaneously with* the happy path, because where and how you
handle errors shapes the entire structure of the code.

Error handling isn't just about catching exceptions — it's about answering a set of
architectural questions: Where should this failure be detected? Where should it be handled?
What should the system's state be after the failure? What information should be communicated,
to whom?

---

## Step 0: Load Error Handling Conventions

Before designing error handling from scratch, check whether the team has established
patterns. Inconsistent error handling across a codebase is worse than mediocre-but-consistent
error handling.

**If gjalla is available**, query these tools first:

- `get_context(scope="rules")` — check for ADRs or principles about error handling
  strategy. The team may have already decided on Result types vs. exceptions, error
  response formats, retry policies, or circuit breaker patterns.
- `get_context(scope="architecture")` — understand the error boundary layers (where do
  controllers live? middleware? global error handlers?) so your error handling fits the
  existing architecture.

**If gjalla is not available**, scan 2-3 existing endpoints or service methods for error
handling patterns. Look for error middleware, shared error classes, and logging conventions.

---

## The Core Questions

For every operation that can fail (I/O, validation, business rule checks, external calls),
answer these questions:

### 1. Where Should the Error Be Caught?

Not every error should be caught where it occurs. The right place to handle an error is the
layer that has enough context to do something meaningful about it.

**Catch at the call site** when:
- You can retry the operation
- You have a fallback or default value
- The error is expected and part of normal flow (e.g., "user not found" during lookup)
- You need to transform the error into a domain-specific error

**Let it propagate** when:
- The current layer doesn't know what to do with the error
- The caller needs to decide how to respond
- Catching would just re-throw with no added value
- The error represents a genuine failure that should stop the operation

**Catch at a boundary** (controller, API handler, job runner) when:
- You need to translate internal errors into external error responses
- You need to ensure cleanup happens regardless of what failed
- You need to log the error with full request context

The anti-pattern to avoid: catching an error, logging it, and re-throwing it at every layer.
This creates duplicate log entries and adds no value. Log at the boundary where you have
full context, not at every intermediate layer.

### 2. What State Does Failure Leave?

This is the most critical and most overlooked question. When an operation fails partway
through, what state is the system in?

**Atomic operations** — either everything succeeds or nothing does:
- Use database transactions for multi-step data changes
- Use the saga pattern for distributed operations that span services
- Roll back partial state on failure

**Idempotent operations** — safe to retry without side effects:
- Use idempotency keys for operations that create resources
- Make retry logic safe by checking for existing state before creating new state
- Design APIs so that calling them twice with the same input produces the same result

**Partial failure** — some steps succeed and some fail:
- Track which steps completed so recovery can resume from where it left off
- Use status fields to record intermediate states
- Provide a way to complete or roll back partial operations

Ask for every multi-step operation: "If this fails after step 2 of 4, what does the
database look like? Can the user retry? Will the retry cause duplicates?"

### 3. What Should the Caller See?

Different callers need different information about failures:

**External API consumers** need:
- A stable error code they can switch on programmatically
- A human-readable message explaining what went wrong
- Enough detail to fix the problem (which field was invalid, what the constraints are)
- No internal implementation details (stack traces, internal service names, database errors)

**Internal service callers** need:
- The error type/category for routing (retryable vs. permanent, client error vs. server error)
- Enough context to log meaningfully
- Correlation IDs for distributed tracing

**End users** need:
- A clear, non-technical explanation of what happened
- Guidance on what to do next (retry, contact support, fix input)
- No scary technical details

**Operators/on-call** need (in logs and alerts):
- The full error with stack trace
- The input that caused the error
- Request context (user ID, request ID, operation name)
- Which dependency failed and how

### 4. Should This Be Retried?

Not all errors are worth retrying. Categorize them:

**Retryable** (transient failures):
- Network timeouts
- Rate limit responses (429)
- Database connection pool exhaustion
- Temporary service unavailability (503)

For retryable errors, implement:
- Exponential backoff with jitter
- Maximum retry count
- Circuit breaker to stop retrying when a dependency is clearly down

**Non-retryable** (permanent failures):
- Validation errors (400)
- Authentication failures (401)
- Resource not found (404)
- Business rule violations

For non-retryable errors, fail fast and return a clear error to the caller.

**Ambiguous** (might be transient or permanent):
- 500 Internal Server Error (could be a bug or a transient issue)
- Connection refused (could be a restart or a configuration problem)

For ambiguous errors, retry a small number of times with backoff, then fail with a clear
error.

---

## Error Handling Patterns

### The Error Boundary Pattern

Define clear layers where errors are caught and translated:

```
Request comes in
  → Controller catches validation errors → returns 400
  → Service layer catches business rule violations → returns 409/422
  → Infrastructure layer catches I/O errors → returns 500 or retries
  → Global error handler catches everything else → returns 500, logs full context
```

Each layer catches only the errors it knows how to handle. Everything else propagates up.

### The Result Pattern (for expected failures)

When failure is a normal part of the operation (not exceptional), use a Result type instead
of exceptions:

```
// Instead of:
function findUser(id): User {  // throws if not found
  ...
}

// Consider:
function findUser(id): Result<User, NotFoundError> {  // returns a result
  ...
}
```

This makes error handling explicit in the type system and forces callers to consider the
failure case. Use this for operations where "not found" or "invalid" is a normal outcome,
not a bug.

### The Compensating Action Pattern (for partial failures)

When a multi-step operation fails partway through, use compensating actions to undo the
completed steps:

```
1. Reserve inventory ✓
2. Charge payment ✓
3. Create shipment ✗ — failed

Compensating actions (reverse order):
2. Refund payment
1. Release inventory reservation
```

Document the compensating action for each step so recovery is systematic, not ad-hoc.

---

## Common Mistakes

**Swallowing errors silently.** An empty catch block is almost always a bug. If you
genuinely want to ignore an error, add a comment explaining why.

**Logging and rethrowing at every layer.** This creates duplicate log entries that make
debugging harder, not easier. Log at the boundary where you have full context.

**Returning generic "something went wrong" errors.** This makes debugging impossible for
both users and operators. Include enough context to identify the problem.

**Not considering partial failure in multi-step operations.** If step 3 of 5 fails, what
state is the system in? If you don't know, neither does the on-call engineer at 3am.

**Treating all errors the same.** A validation error and a database timeout are fundamentally
different failures that require different responses. Categorize your errors.

---

## Output

When implementing error handling, the output is integrated into the code itself — not a
separate document. But for complex features with multiple failure modes, produce a brief
error handling summary in the PR description:

```
## Error Handling

| Operation | Failure Mode | Response | Retry? |
|-----------|-------------|----------|--------|
| Create order | Payment declined | 422 + error code | No |
| Create order | Inventory unavailable | 409 + backorder option | No |
| Create order | Payment timeout | 500 + retry internally | Yes, 3x with backoff |
| Create order | Notification failure | Log warning, proceed | No (non-critical) |

Partial failure: If payment succeeds but shipment creation fails, the payment is
automatically refunded via a compensating transaction.
```

This table is a forcing function — it makes you think through every failure mode before
you encounter them in production.

### Attestation: Error Handling Decisions

Include the error table in the PR and add an attestation:

```
## Error Handling Attestation

**Error handling rules checked**: [ADRs/principles from get_context(scope="rules")]
**Pattern used**: [error boundary, Result type, compensating actions — whatever applies]
**Conventions matched**: [how this follows the existing error handling patterns]
**Partial failure handling**: [how multi-step operations recover from mid-flow failures]
**Retry strategy**: [which operations retry, with what backoff/limits]
```

This ensures the reviewer can verify that error handling was designed intentionally, not
as an afterthought.
