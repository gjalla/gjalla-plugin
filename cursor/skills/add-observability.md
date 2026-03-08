# Add Observability

At companies like Google, Netflix, and Datadog, you can't ship code to production without
observability. The question isn't "does it work in tests" — it's "how will the on-call
engineer know if it stops working at 3am?" This skill ensures code is instrumented so that
problems are detected, diagnosed, and resolved quickly.

Observability has three pillars: logs (what happened), metrics (how much/how fast), and
traces (the path a request took). Most production issues need at least two of these to
diagnose.

---

## Step 0: Load Production Readiness Context

Before instrumenting code, understand what the team expects for production-ready services.

**If gjalla is available**, query these tools first:

- `get_context` (scope: `architecture`) — understand the current monitoring architecture. Are there existing
  dashboards, alerting systems, or tracing infrastructure you should integrate with?
- `get_context` (scope: `rules`) — check for ADRs about logging standards, metric naming, or alerting
  policies.

**If gjalla is not available**, check for existing observability documentation, monitoring
configs, or Grafana/Datadog dashboard definitions in the repo.

---

## Structured Logging

### Principles

Logs should be structured (JSON), not free-text. Structured logs are searchable, filterable,
and parseable by machines. Free-text logs are only useful to humans reading them in real-time.

Every log entry should include:
- **timestamp** — ISO 8601, always UTC
- **level** — debug, info, warn, error (use consistently)
- **message** — human-readable description of what happened
- **context fields** — request_id, user_id, operation name, relevant parameters

### What to Log

- **Request boundaries** — log when a request arrives and when it completes, with duration
- **Decision points** — log when the code takes a branch based on data (feature flags, A/B tests, fallbacks)
- **External calls** — log before and after calls to databases, APIs, queues, with duration and success/failure
- **Errors** — log the full error with stack trace, input that caused it, and any relevant context
- **State changes** — log when important domain objects change state (order placed, payment processed)

### What NOT to Log

- Sensitive data (passwords, tokens, PII, credit card numbers) — redact or omit
- High-frequency events at INFO level that would create noise (log at DEBUG instead)
- Successful health checks (they just create volume)

### Pattern

```
logger.info("payment_processed", {
  order_id: order.id,
  amount_cents: order.amount,
  currency: order.currency,
  payment_method: "card",
  duration_ms: elapsed,
})
```

---

## Metrics

### Key Metrics to Instrument

For every service, instrument the **RED metrics**:

- **Rate** — requests per second (throughput)
- **Errors** — error count and error rate (errors / total requests)
- **Duration** — request latency (p50, p95, p99)

For background jobs and queues, instrument the **USE metrics**:

- **Utilization** — how busy is the resource (CPU, memory, queue depth)
- **Saturation** — how much queued/waiting work exists
- **Errors** — failure count and rate

### Additional Metrics

Beyond RED/USE, consider:
- **Business metrics** — orders processed, payments completed, users signed up
- **Dependency health** — latency and error rate for each external dependency
- **Cache performance** — hit rate, miss rate, eviction rate
- **Queue depth** — for any async processing

### Naming Conventions

Use a consistent naming scheme. A common pattern:
```
{service}_{component}_{metric}_{unit}

Examples:
  api_http_requests_total
  api_http_request_duration_seconds
  api_database_query_duration_seconds
  api_cache_hits_total
  api_payment_amount_dollars
```

---

## Distributed Tracing

For any service that makes calls to other services or databases, add tracing so that a
single request can be followed across the entire system.

### Implementation

- Generate a **trace ID** at the entry point of a request
- Propagate the trace ID through all internal calls and to downstream services (via headers)
- Create **spans** for each significant operation within a request
- Attach relevant **tags** to spans (user_id, operation, status)

### What Gets a Span

- HTTP request handling (the root span)
- Database queries
- Cache lookups
- External API calls
- Message queue publish/consume
- Any operation that takes meaningful time or could fail

---

## Alerting

### Alert Design Principles

**Alert on symptoms, not causes.** Alert when users are affected (high error rate, high
latency), not when a specific internal metric changes (CPU at 80%). Symptom-based alerts
have fewer false positives and catch problems you didn't anticipate.

**Every alert must be actionable.** If the on-call engineer can't do anything about it at
3am, it shouldn't page. Make it a dashboard or a low-priority notification instead.

**Include runbook links.** Every alert should link to a runbook that explains what the alert
means, how to diagnose it, and how to mitigate it.

### Key Alerts

At minimum, set up alerts for:
- Error rate exceeding baseline (e.g., >1% 5xx for 5 minutes)
- Latency exceeding SLO (e.g., p99 > 500ms for 10 minutes)
- Service availability (health check failures)
- Queue depth growing unboundedly
- Critical dependency unavailable

---

## SLOs (Service Level Objectives)

Define what "good enough" looks like for the service:

- **Availability** — e.g., 99.9% of requests succeed (non-5xx) over a 30-day window
- **Latency** — e.g., 99% of requests complete in under 200ms
- **Correctness** — e.g., 99.99% of transactions produce the correct result

SLOs create an error budget — the acceptable amount of failure. When the error budget is
nearly exhausted, the team should prioritize reliability over features.

---

## Output

When adding observability to code, produce:

1. **Instrumented code** — logging, metrics, and tracing added to the implementation
2. **Dashboard specification** — what panels to include on the service dashboard
3. **Alert definitions** — what conditions trigger alerts, with severity levels
4. **SLO definitions** — what the service's reliability targets are

Document the observability setup in a section of the service's README or in a dedicated
`docs/observability.md` file.

### Attestation: Observability as Production Readiness

After adding observability, run the production readiness checklist to verify completeness.

```
## Observability Attestation

**Criteria met**: [list of observability requirements satisfied]
**Criteria deferred**: [any requirements not yet met, with justification]
**SLOs defined**: [availability, latency, correctness targets]
**Alerts configured**: [list of alerts with runbook links]
**Dashboard created**: [link or spec for the service dashboard]
**Rules respected**: [from get_context(scope="rules") — logging/monitoring ADRs followed]
```
