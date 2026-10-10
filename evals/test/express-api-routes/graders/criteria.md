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
- The reply includes the complete generated test file content inline (not merely a description of what the tests would contain), and that code visibly implements the listed scenarios
- Phase 4 validation shows full suite passing

FAIL if:
- Does not identify the three module categories with correct risk levels
- Fails to allocate 5-7 test cases to auth routes
- Does not mock S3 properly in generated tests
- Does not cover password validation, JWT handling, and error cases for auth routes
- Does not cover multipart parsing, file size limits, and S3 failure scenarios for upload routes
- Does not allocate 3-4 test cases for data export
- Describes test scenarios without including the actual test code in the reply
- States or shows that it edited route implementations instead of only creating test files
- Does not use proper async/await assertions in tests
