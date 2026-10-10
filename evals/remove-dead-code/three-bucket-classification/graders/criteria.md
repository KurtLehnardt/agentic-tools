---
type: llm
weight: 1
---

PASS if:
- Bucket 1 (truly dead—delete): orphanedHelper, _validateAdminRole
  - orphanedHelper is never called anywhere (not tests, not production)
  - _validateAdminRole is only called by createAdminPanel, which is itself dead, making it transitively dead
- Bucket 2 (intentional—keep): testHelper
  - testHelper is only referenced in tests (src/api.test.js), not in production
  - But test helpers are bucket 2 by design—tests intentionally call them
  - Should NOT be deleted even though unreachable from entry point
- Bucket 3 (decide—human choice): createAdminPanel and its internal call chain
  - Complete feature with full implementation (authenticate, render, handleDelete)
  - Never called from app entry point or any production code
  - Not even stubbed or partially implemented—fully wired but never connected
  - Clearly unwired rather than incomplete scaffolding
  - Requires human decision: finish, defer, or cut?
- Correctly distinguishes all three buckets with clear reasoning
- Does not delete anything (audit mode)
- Presents each bucket with its items and the decision rationale

FAIL if:
- Misclassifies testHelper as bucket 1 (should be bucket 2)
- Flags testHelper for deletion
- Misses orphanedHelper or _validateAdminRole
- Classifies createAdminPanel as bucket 1 instead of bucket 3
- Suggests deleting createAdminPanel without acknowledging it's unwired, not empty
- Does not distinguish between test-only (bucket 2) and never-called (bucket 1)
- Does not create a bucket 3 and explain when human judgment is needed
- Attempts to delete without explicit audit-and-fix authorization
