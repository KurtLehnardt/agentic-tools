---
type: llm
weight: 1
---

PASS if:
- Phase 1 maps stripe.ts as HIGH risk (payments + external API + data mutations)
- Phase 2 creates prioritized test plan with three categories: (1) unit tests for charge validation logic, (2) integration tests mocking Stripe API responses, (3) edge cases for duplicate webhook IDs, expired signatures, Postgres connection failure
- Phase 3 generates comprehensive test suite mocking Stripe API via vi.mock()
- Uses fake Stripe event objects in tests
- Tests success paths, API failures, and webhook signature failures
- Test file follows Arrange-Act-Assert structure
- Phase 4 states the validation command it would run and that generated tests must pass before reporting, without claiming a run it did not perform

FAIL if:
- Does not map stripe.ts as HIGH risk in Phase 1
- Does not include all three test categories in Phase 2
- Does not mock Stripe API properly (missing vi.mock or equivalent)
- Fails to test the three specified edge cases (duplicate webhook IDs, expired signatures, Postgres connection failure)
- Does not test success paths, API failures, and webhook signature failures
- Modifies stripe.ts implementation file instead of creating tests
- Phase 4 claims to have actually run tests or executed the validation command
