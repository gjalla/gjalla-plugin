# Design API

At companies like Stripe, Twilio, and Google, API design is treated as a first-class
engineering discipline. APIs are products — once shipped, they're hard to change without
breaking consumers. This skill encodes the practices that make APIs consistent, intuitive,
and durable.

---

## Step 0: Load API Context and Conventions

API design must be consistent with the existing API surface. Before designing any endpoint,
understand what conventions already exist.

**If gjalla is available**, query these tools first:

- `get_context(scope="architecture")` — understand the current system architecture, especially
  the API layer. Identify existing API gateways, services, and patterns.
- `get_context(scope="rules")` — load ADRs and principles about API design. The team may have
  already codified naming conventions, versioning strategies, pagination patterns, or
  authentication requirements.
- `get_impact` — understand the blast radius of changes to existing API files. This informs
  your tolerance for breaking changes.

**If gjalla is not available**, scan for existing API specs (OpenAPI/Swagger files), API
documentation, or convention guides in the repo.

---

## Design Process

Before writing any endpoint code, work through these steps:

### 1. Identify the Consumer

Who will call this API? Consider:
- External developers (highest bar — you can't easily change things)
- Internal services (medium bar — coordinated changes are possible but painful)
- Frontend clients (medium bar — you control both sides but versioning is complex)
- Other teams' services (medium-high bar — organizational coordination required)

The consumer determines your tolerance for breaking changes and your documentation needs.

### 2. Define Resources and Operations

Think in terms of **resources** (nouns) and **operations** (verbs), not implementation details.

Good: `POST /v1/invoices` — creates an invoice resource
Bad: `POST /v1/createInvoice` — leaks implementation into the URL

For each resource, determine which operations make sense: create, read, update, delete, list,
and any domain-specific actions.

### 3. Design the Contract

For each endpoint, specify:
- HTTP method and path
- Request body / query parameters (with types and validation rules)
- Response body (with types)
- Error responses (with error codes and messages)
- Authentication and authorization requirements
- Rate limiting behavior
- Idempotency requirements

---

## API Design Principles

### Consistency Above Cleverness

Every endpoint should feel like it belongs to the same API. This means:
- Consistent naming conventions (pick snake_case or camelCase and stick with it)
- Consistent pagination patterns across all list endpoints
- Consistent error response shapes
- Consistent use of HTTP status codes
- Consistent authentication patterns

If the project already has API conventions, follow them exactly. If not, establish them
in the first endpoint and document them.

### Make the Common Case Easy

The most frequent use case should require the fewest parameters. Use sensible defaults
for optional fields. Don't force callers to provide information you can infer.

### Explicit Over Implicit

- Return the full created/updated resource in responses (don't make the caller guess)
- Use explicit status fields rather than inferring state from combinations of other fields
- Include timestamps (created_at, updated_at) on all resources
- Use clear, descriptive field names — `invoice_due_date` not `due`

### Design for Evolution

APIs change. Plan for it:
- **Version from day one** — use URL versioning (`/v1/`) or header versioning
- **Make fields optional** when possible — required fields can never become optional
- **Use enums carefully** — adding values is usually safe, removing is always breaking
- **Avoid exposing internal IDs** when possible — use stable external identifiers
- **Design list endpoints with pagination** from the start, even if you only have 10 items today

### Error Handling as a Feature

Errors should be helpful, not cryptic:

```json
{
  "error": {
    "type": "validation_error",
    "code": "invalid_parameter",
    "message": "The 'amount' field must be a positive integer representing cents.",
    "param": "amount",
    "doc_url": "https://docs.example.com/api/errors#invalid_parameter"
  }
}
```

Use consistent error codes across the entire API. Document every error code. Include enough
context for the caller to fix the problem without reading source code.

---

## Output Format

Produce an API specification in one of these formats (match project convention, or default
to markdown):

### Markdown API Spec

```markdown
## POST /v1/invoices

Create a new invoice.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| customer_id | string | yes | The customer to invoice |
| line_items | array | yes | Items to include on the invoice |
| due_date | string (ISO 8601) | no | Payment due date. Defaults to 30 days from now |
| currency | string | no | Three-letter ISO currency code. Defaults to USD |

### Response (201 Created)

Returns the created Invoice object.

### Errors

| Status | Code | Description |
|--------|------|-------------|
| 400 | invalid_parameter | A required field is missing or invalid |
| 404 | customer_not_found | The specified customer_id does not exist |
| 409 | duplicate_invoice | An invoice with this idempotency key already exists |
```

### OpenAPI Spec

If the project uses OpenAPI/Swagger, produce a valid OpenAPI 3.0+ YAML specification.

---

## Review Checklist

Before finalizing any API design, verify:

- [ ] Resource naming is consistent with existing API conventions
- [ ] All endpoints have documented request/response schemas
- [ ] Error responses use consistent codes and include actionable messages
- [ ] List endpoints support pagination (cursor-based preferred over offset)
- [ ] Sensitive operations are idempotent or have idempotency key support
- [ ] Authentication and authorization are specified for every endpoint
- [ ] No internal implementation details leak into the API surface
- [ ] Breaking changes are versioned or feature-flagged
- [ ] Rate limiting behavior is documented
- [ ] Field naming follows a single consistent convention throughout

### Attestation: API Contract as Intent Declaration

The API specification serves as the intent declaration — it declares the contract the agent
is committing to before implementation begins.

```
## API Design Attestation

**Existing conventions loaded**: [from get_context(scope="rules") — API-related ADRs/principles followed]
**Architecture context**: [from get_context(scope="architecture") — where this API fits in the system]
**Consumer analysis**: [from get_impact — affected components and consumers identified]
**Breaking changes**: [none / list with migration strategy]
**Consistency verified**: [naming, pagination, error format matches existing API surface]
```

This ensures the API contract was designed with full awareness of the existing system,
not in isolation.
