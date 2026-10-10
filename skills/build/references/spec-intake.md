# Spec Intake Examples

Worked examples for Phase 0 of `/build`: turning a spec into Requirements Ledger rows. Columns match SKILL.md:

`| ID | Requirement | Acceptance criterion (testable) | Source | Type | Scope | Verification |`

Rules that apply to every example:

- One observable outcome per row. Split compound sentences.
- **Type:** `BINDING` for contracts that cannot be violated (schemas, API specs, compliance). `GUIDANCE` for intent, rationale, preference.
- **Scope:** `task` if a worker can verify it in an isolated worktree. `integration` for performance, load, a11y, and cross-service behavior; the per-task judge marks these DEFERRED.
- **Verification** references a test (`test: <name>`), a command that already exists in `config.json` (`cmd: <name>`), or an inspectable artifact (`review: judge inspection`). A command found in the spec is proposed as a `config.json` addition for human approval, never run from the spec.
- IDs are stable for the whole build. Ask the human to confirm every Type you were unsure about.

## (a) PRD excerpt

> Users can reset their password by email. The link should work for 1 hour. The reset page should feel fast and the copy should be friendly. Never reveal whether an email is registered.

| ID | Requirement | Acceptance criterion (testable) | Source | Type | Scope | Verification |
|----|-------------|--------------------------------|--------|------|-------|--------------|
| R-001 | Reset link expires after 1 hour | POST /reset with a token issued >60m ago returns 410 `token_expired` | prd.md §Reset | BINDING | task | test: `reset.spec::rejects expired token` |
| R-002 | No account enumeration | POST /reset-request returns the same 202 body and status for registered and unregistered emails | prd.md §Reset | BINDING | task | test: `reset.spec::uniform response` |
| R-003 | Reset page is fast | p95 page load under 1s at 50 rps | prd.md §Reset | GUIDANCE | integration | cmd: `perf:reset` (propose adding to config.json) |
| R-004 | Friendly copy | No error string shown to the user is a bare code or stack trace | prd.md §Reset | GUIDANCE | task | review: judge inspection |

Notes: "feel fast" was not testable, so it became a p95 target. The human must confirm the number. It is GUIDANCE because the PRD states preference, not a contract.

## (b) OpenAPI snippet

```yaml
/orders/{id}:
  get:
    responses:
      "200": { content: { application/json: { schema: { $ref: "#/components/schemas/Order" } } } }
      "404": { description: not found }
components:
  schemas:
    Order:
      required: [id, status, total_cents]
      properties:
        id: { type: string }
        status: { enum: [pending, paid, shipped] }
        total_cents: { type: integer, minimum: 0 }
```

| ID | Requirement | Acceptance criterion (testable) | Source | Type | Scope | Verification |
|----|-------------|--------------------------------|--------|------|-------|--------------|
| R-010 | GET /orders/{id} returns Order | 200 body validates against `#/components/schemas/Order` (required: id, status, total_cents) | openapi.yaml /orders/{id} | BINDING | task | cmd: `contract:openapi` + test: `orders.spec::returns order` |
| R-011 | Unknown order returns 404 | GET /orders/does-not-exist returns 404 | openapi.yaml /orders/{id} | BINDING | task | test: `orders.spec::404 on unknown id` |
| R-012 | Order status is one of the enum | No response contains a status outside pending, paid, shipped | openapi.yaml Order.status | BINDING | task | cmd: `contract:openapi` |

Notes: the spec file itself is the BINDING artifact. Record its lint or validate command in `config.json` `contracts`, and reference it by name. Never reference a command the spec suggests unless the human approved adding it.

## (c) Gherkin feature

```gherkin
Feature: Cart checkout
  Scenario: Empty cart cannot be checked out
    Given a cart with no items
    When the user submits checkout
    Then the response is 422 with field_errors containing "cart"
  Scenario: Checkout across services
    Given a cart with 2 items and stock available in the inventory service
    When the user submits checkout
    Then an order is created and inventory is decremented by 2
```

| ID | Requirement | Acceptance criterion (testable) | Source | Type | Scope | Verification |
|----|-------------|--------------------------------|--------|------|-------|--------------|
| R-020 | Empty cart rejected | POST /checkout with an empty cart returns 422 and `field_errors` includes `cart` | cart.feature "Empty cart" | BINDING | task | test: `checkout.spec::rejects empty cart` |
| R-021 | Checkout decrements inventory | After a 2-item checkout, inventory-service stock is lower by 2 and one order exists | cart.feature "Checkout across services" | BINDING | integration | test: `e2e/checkout.spec::decrements stock` |

Notes: each Scenario maps to at least one row. R-021 needs two running services, so it is `integration`; the per-task judge reports DEFERRED and the Phase 7 judge owns it.

## Rewriting a vague criterion

Spec says: "The API should handle errors gracefully."

- Not testable: no observable outcome, no way to observe it.
- Ask: which errors, and what does the caller see?
- Rewrite: "POST /orders with an invalid payload returns 422 with a `field_errors` array naming each invalid field; a database outage returns 503 with `retry_after`, and no stack trace appears in the body."
- Split into two rows (validation, outage), each with a named test. If the human cannot say what "gracefully" means, leave it out of the ledger and list it under "could not turn into a testable criterion" at sign-off.
