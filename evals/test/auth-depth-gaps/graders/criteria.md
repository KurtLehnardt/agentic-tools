---
type: llm
weight: 1
---

PASS if:
- Phase 1 coverage analysis shows auth.ts as SHALLOW (has tests but missing error/edge cases) and export.ts as UNTESTED, both HIGH risk
- Phase 2 prioritizes auth depth improvement first with new test cases for: token refresh validation, concurrent session conflicts, 2FA verification flows
- Phase 2 includes data export with new tests for: CSV header generation, large file handling, permission checks
- Phase 3 generates focused test suite targeting gaps: new auth tests covering session expiry with concurrent requests and refresh token reuse detection
- Phase 3 generates new export tests covering CSV format and access control
- Tests only reveal behavior the implementation already handles (not adding defensive checks to the implementation)
- The reply includes the complete generated test file content inline (not merely a description of what the tests would contain), and that code visibly implements the listed scenarios
- Phase 4 states the validation command it would run and that generated tests must pass before reporting, without claiming a run it did not perform

FAIL if:
- Does not distinguish between SHALLOW coverage for auth.ts and UNTESTED for export.ts
- Does not prioritize auth depth improvements in Phase 2
- Fails to include both modules in the test plan
- Does not cover the specified gaps (token refresh, session expiry, concurrent login, 2FA for auth; CSV header, large files, permissions for export)
- Does not test session expiry with concurrent requests or refresh token reuse detection
- Does not test CSV format and access control for export
- Describes test scenarios without including the actual test code in the reply
- States or shows that it edited or rewrote auth.ts or export.ts to make tests pass, instead of only adding tests
- Phase 4 claims to have actually run tests or executed the validation command
