---
type: llm
weight: 1
---

PASS if:
- Produces coverage analysis identifying three module categories by risk: HIGH (user auth routes), MEDIUM (file uploads with S3 dependency), MEDIUM (data export)
- Test plan allocates resources appropriately: auth routes get 5-7 test cases each covering password validation, JWT handling, and error cases
- Test plan covers upload routes with mocks for S3 and tests for multipart parsing, file size limits, and S3 failure scenarios
- Test plan allocates 3-4 test cases for data export
- Phase 3 generates test files using test-writer-prompt patterns with vi.mock for S3 and proper async/await assertions
- Phase 4 validation shows full suite passing

FAIL if:
- Does not identify the three module categories with correct risk levels
- Fails to allocate 5-7 test cases to auth routes
- Does not mock S3 properly in generated tests
- Does not cover password validation, JWT handling, and error cases for auth routes
- Does not cover multipart parsing, file size limits, and S3 failure scenarios for upload routes
- Does not allocate 3-4 test cases for data export
- Modifies route implementations instead of creating test files
- Does not use proper async/await assertions in tests
