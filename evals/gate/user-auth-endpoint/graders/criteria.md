---
type: llm
weight: 1
---

PASS if:
- Produces a runnable test suite (Jest, pytest, or shell script per project conventions)
- Contains at least 3 assertions covering both positive and negative paths
- Assertion 1: valid email and password return 200 with both access_token and user_id fields present in response
- Assertion 2: missing email parameter returns 400 or higher status code
- Assertion 3: response does NOT contain password or secret fields
- Demonstrates that a hollow stub (one that echoes request parameters without validation) fails the gate
- Reports which specific assertion rejected the stub
- Provides the exact command to re-run the gate (e.g., 'npm test auth.gate.js' or 'pytest test_auth_gate.py')

FAIL if:
- Gate does not reject a hollow stub that echoes request parameters without validation
- Produces fewer than 3 assertions
- Does not test for access_token field in response
- Does not test for user_id field in response
- Does not test rejection of requests with missing email parameter
- Does not assert that password or secret fields are absent from response
- Does not report which assertion rejected the stub
- Does not provide the exact re-run command
