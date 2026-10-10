---
type: llm
weight: 1
---

PASS if:
- Coverage analysis categorizes the file as UNTESTED at HIGH risk
- Identifies tight coupling points: direct DB import, inline HTTP calls, stdout logging
- Explains why tests would be brittle and implementation-coupled
- Provides specific refactoring recommendations: extract business logic, inject DB client, mock external API
- Offers clear assessment of the architectural problem
- If writing any tests, they are narrow integration tests that work around the coupling, not rewriting the implementation, and the complete test file content is included in the reply

FAIL if:
- Does not categorize the file as UNTESTED and HIGH risk
- Fails to identify the tight coupling points (direct DB import, inline HTTP, stdout logging)
- Does not explain why tests would be brittle and implementation-coupled
- States or shows that it edited or rewrote the implementation to make tests pass (should NOT rewrite to pass hollow stubs)
- Forces meaningless tests without addressing the coupling problem
